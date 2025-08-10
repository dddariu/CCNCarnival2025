const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CCNCarnival2025", function () {
  let CCN, ccn, owner, buyer;

  beforeEach(async () => {
    [owner, buyer] = await ethers.getSigners();
    CCN = await ethers.getContractFactory("CCNCarnival2025");
    ccn = await CCN.deploy();
    await ccn.waitForDeployment();
  });

  it("Registers a stall", async () => {
    await ccn.registerStall(0);
    const stall = await ccn.stalls(1);
    expect(stall.owner).to.equal(owner.address);
  });

  it("Accepts a payment", async () => {
    await ccn.registerStall(0);
    await ccn.connect(buyer).makePayment(1, { value: ethers.parseEther("1") });
    const stall = await ccn.stalls(1);
    expect(stall.balance).to.equal(ethers.parseEther("1"));
  });

  it("Owner can issue a refund to a buyer", async () => {
    // Register a stall
    await ccn.registerStall(0);

    // Buyer makes a payment
    await ccn.connect(buyer).makePayment(1, { value: ethers.parseEther("1") });

    // Refund the buyer
    await expect(ccn.issueRefund(1, buyer.address))
      .to.emit(ccn, "RefundIssued")
      .withArgs(1, buyer.address, ethers.parseEther("1"));

    // Check balances updated
    const stall = await ccn.stalls(1);
    expect(stall.balance).to.equal(0);

    const buyerPayment = await ccn.payments(1, buyer.address);
    expect(buyerPayment).to.equal(0);
  });

  it("Owner can withdraw stall funds", async () => {
    // Register a stall
    await ccn.registerStall(0);

    // Buyer makes payment
    await ccn.connect(buyer).makePayment(1, { value: ethers.parseEther("2") });

    // Withdraw
    await expect(ccn.withdrawFunds(1))
      .to.emit(ccn, "FundsWithdrawn")
      .withArgs(1, owner.address, ethers.parseEther("2"));

    // Stall should now have 0 balance and withdrawn = true
    const stall = await ccn.stalls(1);
    expect(stall.balance).to.equal(0);
    expect(stall.withdrawn).to.equal(true);
  });
});
