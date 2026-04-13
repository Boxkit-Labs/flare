#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, BytesN, Env};

#[contracttype]
pub enum DataKey {
    Admin,
    WasmHash,
}

#[contract]
pub struct FactoryContract;

#[contractimpl]
impl FactoryContract {
    pub fn __constructor(env: &Env, admin: Address, wasm_hash: BytesN<32>) {
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::WasmHash, &wasm_hash);
    }

    pub fn admin(env: &Env) -> Address {
        env.storage().instance().get(&DataKey::Admin).unwrap()
    }

    pub fn wasm_hash(env: &Env) -> BytesN<32> {
        env.storage().instance().get(&DataKey::WasmHash).unwrap()
    }

    pub fn set_wasm(env: &Env, wasm_hash: BytesN<32>) {
        env.storage().instance().set(&DataKey::WasmHash, &wasm_hash);
    }

    pub fn open(env: &Env, salt: BytesN<32>, token: Address, from: Address, commitment_key: BytesN<32>, to: Address, amount: i128, refund_waiting_period: u32) -> Address {
        if amount > 0 {
            from.require_auth();
        }

        let wasm_hash = Self::wasm_hash(env);
        let channel_address = env
            .deployer()
            .with_current_contract(salt)
            .deploy_v2(wasm_hash, (token, from, commitment_key, to, amount, refund_waiting_period));

        channel_address
    }
}

mod test;
