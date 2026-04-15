#![no_std]
#[allow(unused_imports)]
use soroban_sdk::{assert_with_error, contract, contracterror, contractimpl, contracttype, symbol_short, token, xdr::ToXdr, Address, Bytes, BytesN, Env, Symbol};

pub mod event;

#[contracterror]
#[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
#[repr(u32)]
pub enum Error {
    NegativeAmount = 1,
    NotClosed = 2,
    RefundWaitingPeriodNotElapsed = 3,
    AlreadyClosed = 4,
}

#[contracttype]
pub enum DataKey {
    Token,
    From,
    CommitmentKey,
    To,
    RefundWaitingPeriod,
    WithdrawnAmount,
    CloseEffectiveAtLedger,
}

#[contracttype]
pub struct Commitment {
    domain: Symbol,
    network: BytesN<32>,
    channel: Address,
    amount: i128,
}

impl Commitment {
    pub fn new(channel: Address, amount: i128) -> Self {
        let network = channel.env().ledger().network_id();
        Commitment {
            domain: symbol_short!("chancmmt"),
            network,
            channel,
            amount,
        }
    }

    fn into_bytes(&self) -> Bytes {
        let env = self.channel.env();
        self.to_xdr(env)
    }

    fn verify(self, sig: &BytesN<64>) {
        let env = self.channel.env().clone();
        let commitment_key: BytesN<32> = env.storage().instance().get(&DataKey::CommitmentKey).unwrap();
        let payload = self.into_bytes();
        env.crypto().ed25519_verify(&commitment_key, &payload, sig);
    }
}

#[contract]
pub struct Contract;

#[contractimpl]
impl Contract {
    pub fn __constructor(
        env: Env,
        token: Address,
        from: Address,
        commitment_key: BytesN<32>,
        to: Address,
        amount: i128,
        refund_waiting_period: u32,
    ) {
        if env.storage().instance().has(&DataKey::Token) {
            panic!("Already initialized");
        }

        if amount > 0 {
            from.require_auth();
            let tc = token::Client::new(&env, &token);
            tc.transfer(&from, &env.current_contract_address(), &amount);
        }

        env.storage().instance().set(&DataKey::Token, &token);
        env.storage().instance().set(&DataKey::From, &from);
        env.storage().instance().set(&DataKey::CommitmentKey, &commitment_key);
        env.storage().instance().set(&DataKey::To, &to);
        env.storage().instance().set(&DataKey::RefundWaitingPeriod, &refund_waiting_period);

        env.events().publish_event(&event::Open {
            from,
            commitment_key,
            to,
            token,
            amount: 0,
            refund_waiting_period,
        });
    }

    pub fn top_up(env: &Env, amount: i128) {
        assert_with_error!(env, amount >= 0, Error::NegativeAmount);
        if amount > 0 {
            let from = Self::from(env);
            from.require_auth();
            Self::token_client(env).transfer(&from, &env.current_contract_address(), &amount);
        }
    }

    pub fn token(env: &Env) -> Address {
        env.storage().instance().get(&DataKey::Token).unwrap()
    }

    pub fn from(env: &Env) -> Address {
        env.storage().instance().get(&DataKey::From).unwrap()
    }

    pub fn to(env: &Env) -> Address {
        env.storage().instance().get(&DataKey::To).unwrap()
    }

    pub fn refund_waiting_period(env: &Env) -> u32 {
        env.storage().instance().get(&DataKey::RefundWaitingPeriod).unwrap()
    }

    pub fn balance(env: &Env) -> i128 {
        Self::token_client(env).balance(&env.current_contract_address())
    }

    pub fn deposited(env: &Env) -> i128 {
        Self::balance(env) + Self::withdrawn(env)
    }

    pub fn withdrawn(env: &Env) -> i128 {
        env.storage().instance().get(&DataKey::WithdrawnAmount).unwrap_or(0)
    }

    pub fn prepare_commitment(env: &Env, amount: i128) -> Bytes {
        assert_with_error!(&env, amount >= 0, Error::NegativeAmount);
        Commitment::new(env.current_contract_address(), amount).into_bytes()
    }

    pub fn settle(env: &Env, amount: i128, sig: BytesN<64>) {
        assert_with_error!(&env, amount >= 0, Error::NegativeAmount);

        let to = Self::to(env);
        to.require_auth();
        Commitment::new(env.current_contract_address(), amount).verify(&sig);

        let payout = amount - Self::withdrawn(env);
        if payout > 0 {
            env.storage().instance().set(&DataKey::WithdrawnAmount, &amount);
            Self::token_client(env).transfer(&env.current_contract_address(), &to, &payout);
            env.events().publish_event(&event::Withdraw { to, amount: payout });
        }
    }

    pub fn close(env: &Env, amount: i128, sig: BytesN<64>) {
        assert_with_error!(&env, amount >= 0, Error::NegativeAmount);

        let to = Self::to(env);
        to.require_auth();
        Commitment::new(env.current_contract_address(), amount).verify(&sig);

        let payout = amount - Self::withdrawn(env);
        if payout > 0 {
            env.storage().instance().set(&DataKey::WithdrawnAmount, &amount);
            Self::token_client(env).transfer(&env.current_contract_address(), &to, &payout);
            env.events().publish_event(&event::Withdraw { to, amount: payout });
        }

        let effective_at_ledger = env.ledger().sequence();
        let already_effective = Self::close_effective_at_ledger(env).is_some_and(|l| l <= effective_at_ledger);
        if !already_effective {
            env.storage().instance().set(&DataKey::CloseEffectiveAtLedger, &effective_at_ledger);
            env.events().publish_event(&event::Close { effective_at_ledger });
        }

        let from = Self::from(env);
        let tc = Self::token_client(env);
        let balance = tc.balance(&env.current_contract_address());
        if balance > 0 {
            if tc.try_transfer(&env.current_contract_address(), &from, &balance).is_ok() {
                env.events().publish_event(&event::Refund { from, amount: balance });
            }
        }
    }

    pub fn close_start(env: &Env) -> Result<(), Error> {
        if let Some(effective_at_ledger) = Self::close_effective_at_ledger(env) {
            if env.ledger().sequence() >= effective_at_ledger {
                return Err(Error::AlreadyClosed);
            }
        }

        let from = Self::from(env);
        from.require_auth();

        let refund_waiting_period = Self::refund_waiting_period(env);
        let effective_at_ledger = env.ledger().sequence().saturating_add(refund_waiting_period);
        env.storage().instance().set(&DataKey::CloseEffectiveAtLedger, &effective_at_ledger);

        env.events().publish_event(&event::Close { effective_at_ledger });
        Ok(())
    }

    pub fn refund(env: &Env) -> Result<(), Error> {
        let effective_at_ledger = Self::close_effective_at_ledger(env).ok_or(Error::NotClosed)?;
        if env.ledger().sequence() < effective_at_ledger {
            return Err(Error::RefundWaitingPeriodNotElapsed);
        }

        let from = Self::from(env);
        from.require_auth();

        let tc = Self::token_client(env);
        let balance = tc.balance(&env.current_contract_address());
        if balance > 0 {
            tc.transfer(&env.current_contract_address(), &from, &balance);
            env.events().publish_event(&event::Refund { from, amount: balance });
        }
        Ok(())
    }
}

impl Contract {
    fn token_client(env: &Env) -> token::Client<'_> {
        token::Client::new(env, &Self::token(env))
    }

    fn close_effective_at_ledger(env: &Env) -> Option<u32> {
        env.storage().instance().get(&DataKey::CloseEffectiveAtLedger)
    }
}

mod test;
