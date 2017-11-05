defmodule Neoscan.Explanations do
  @moduledoc false
  @explanations %{
    # blocks
    "block_hash" => "hash of all of the info stored in a block, including, but not limited to, the index, time, merkle root, etc...",
    "block_index" => "position of this block in the overall chain of blocks forming the 'blockchain'",
    "block_transactions" => "list of transactions included in this block",
    "block_time" => "time the block was formed",
    "block_version" => "??the current version of the blockchain system used by NEO??",
    "block_merkle_root" => "each transaction in a block is hashed. all of the individual transaction hashes together are then hashed to form a new hash; this combined hash is known as the merkle root.",
    "block_validator" => "public address of the consensus node that first announced the transaction",
    "block_size" => "total size of the block in kilobytes",
    "block_previous_block" => "block hash of the previous block",
    "block_next_block" => "block hash of the next block",
    "block_confirmations" => "number of blocks that have been created after this block",

    # scripts
    "bytecode_invocation_script" => "hex string of the Elliptic Curve Digital Signature Algorithm (ECDSA) signature that is generated from the transaction data and a user's private key. This signature is used by the verification script to check against the public key",
    "bytecode_verification_script" => "hex string for checking the public key against the Elliptic Curve Digital Signature Algorithm (ECDSA) signature",
    "opcode_invocation_script" => "a human readable format of the bytecode invocation script",
    "opcode_verification_script" => "a human readable format of the bytecode verification script",

    # transactions
    "transaction_type" => "types of transactions can be claim, for claiming gas; contract, for sending NEO and GAS; invocation, for calling a smart contract; and miner, for validation of the block by a consensus node",
    "transaction_hash" => "hash of all the information in the transaction",
    "transaction_time" => "time the transaction was included in the blockchain",
    "transaction_size" => "size of the transaction in bytes",
    "transaction_confirmations" => "number of blocks that have been created after the block containing this transaction",
    "transaction_network_fees" => "gas charged by the consensus nodes for confiming a transaction and including it in the blockchain.",
    "transaction_system_fees" => "cost in gas charged under<a href=\"http://docs.neo.org/en-us/sc/systemfees.html\">NEO system fees</a> for confiming a transaction and including it in the blockchain. The system fees are distributed to NEO holders",
    "transaction_spent" => "after the transaction has been completed, coins that have been sent to another address",
    "transaction_unspent" => "after the transaction has been completed, coins that remain in the same address",

    # addresses
    "address_hash" => "hash of a public address",
    "address_balance" => "NEO and GAS held by an address. Note: other tokens are stored in smart contracts",
    "address_unclaimed" => "Gas generated by NEO needs to be claimed by an address owner before it can be spent. Gas is generated by NEO holders through system fees or blocks generated over approximately the first 22 years of the NEO blockchain",
    "address_created" => "time the address was created",
    "address_transactions" => "history of the transactions for the address",
    "address_first_transaction" => "first transaction ever made by the address",
  }

  def get_explanation(topic) do
    case Map.fetch(@explanations, topic) do
      {:ok, explanation} -> {:ok, explanation}
      :error -> {:error, "failed to find this explanation"}
    end
  end
end