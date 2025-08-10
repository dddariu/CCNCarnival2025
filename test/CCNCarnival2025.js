const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CCNCarnival2025", function () {
  let CCN, ccn, owner, buyer;

  beforeEach(async () => {
    [owner, buyer] = await ethers.getSigners();
    CCN = await ethers.getContractFactory("CCNCarnival2025");
    ccn = await CCN.deploy();
    await ccn.deployed();
  });

  it("Registers a stall", async () => {
    await ccn.registerStall(0);
    const stall = await ccn.stalls(1);
    expect(stall.owner).to.equal(owner.address);
  });

  it("Accepts a payment", async () => {
    await ccn.registerStall(0);
    await ccn.connect(buyer).makePayment(1, { value: ethers.utils.parseEther("1") });
    const stall = await ccn.stalls(1);
    expect(stall.balance).to.equal(ethers.utils.parseEther("1"));
  });
});