use soroban_sdk::{contractevent, Address, BytesN};

#[contractevent]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Open {
    pub from: Address,
    pub commitment_key: BytesN<32>,
    pub to: Address,
    pub token: Address,
    pub amount: i128,
    pub refund_waiting_period: u32,
}

#[contractevent]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Close {
    pub effective_at_ledger: u32,
}

#[contractevent]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Withdraw {
    pub to: Address,
    pub amount: i128,
}

#[contractevent]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Refund {
    pub from: Address,
    pub amount: i128,
}
