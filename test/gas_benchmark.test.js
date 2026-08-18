const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Eco Energy Hub DAO Gas Benchmarks", function () {
  let ceToken, governorQV, timelock;
  let owner, voter1, voter2, g1, g2, g3, g4, g5;

  before(async function () {
    [owner, voter1, voter2, g1, g2, g3, g4, g5] = await ethers.getSigners();

    // 1. Deploy CEToken
    const CEToken = await ethers.getContractFactory("CEToken");
    ceToken = await CEToken.deploy();
    await ceToken.waitForDeployment();

    // 2. Deploy GovernorQV
    const GovernorQV = await ethers.getContractFactory("GovernorQV");
    governorQV = await GovernorQV.deploy(await ceToken.getAddress());
    await governorQV.waitForDeployment();

    // 3. Deploy TimelockGuardian
    const TimelockGuardian = await ethers.getContractFactory("TimelockGuardian");
    timelock = await TimelockGuardian.deploy([
      g1.address,
      g2.address,
      g3.address,
      g4.address,
      g5.address,
    ]);
    await timelock.waitForDeployment();
  });

  it("Benchmark 1: Identity Verification & Token Minting Gas", async function () {
    // Verify identity with address and physical SDP ID string
    const txVerify = await ceToken.verifyIdentity(voter1.address, "SDP-IE-12345");
    const receiptVerify = await txVerify.wait();
    console.log(`\n -> verifyIdentity() Gas Used: ${receiptVerify.gasUsed.toString()}`);

    // Mint 100 CET
    const amount = ethers.parseEther("100");
    const txMint = await ceToken.mint(voter1.address, amount);
    const receiptMint = await txMint.wait();
    console.log(` -> mint() Gas Used: ${receiptMint.gasUsed.toString()}`);
  });

  it("Benchmark 2: Proposal Creation & Quadratic Voting Gas", async function () {
    // Verify identity & Mint deposit to owner
    await ceToken.verifyIdentity(owner.address, "SDP-IE-00001");
    await ceToken.mint(owner.address, ethers.parseEther("100"));

    // Create Proposal
    const txProp = await governorQV.createProposal("QmHashExampleIpfsFs12345");
    const receiptProp = await txProp.wait();
    console.log(` -> createProposal() Gas Used: ${receiptProp.gasUsed.toString()}`);

    // Cast 5 Quadratic Votes (n=5, cost = 25 VCs)
    const txVote = await governorQV.connect(voter1).castVote(1, 5);
    const receiptVote = await txVote.wait();
    console.log(` -> castVote() (n=5 votes) Gas Used: ${receiptVote.gasUsed.toString()}`);
  });

  it("Benchmark 3: Timelock Queue & Guardian Emergency Pause Gas", async function () {
    const txHash = ethers.keccak256(ethers.toUtf8Bytes("ExecuteProposal#1"));

    // Queue Transaction
    const txQueue = await timelock.queueTransaction(txHash);
    const receiptQueue = await txQueue.wait();
    console.log(` -> queueTransaction() Gas Used: ${receiptQueue.gasUsed.toString()}`);

    // Guardian Emergency Pause
    const txPause = await timelock.connect(g1).emergencyPause();
    const receiptPause = await txPause.wait();
    console.log(` -> emergencyPause() Gas Used: ${receiptPause.gasUsed.toString()}\n`);
  });
});