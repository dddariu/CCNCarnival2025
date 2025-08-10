const { expect } = require("chai");

describe("CCNCarnival2025", function () {
  let CCN, ccn, owner, buyer;

  beforeEach(async () => {
    const [owner, buyer] = await ethers.getSigners();
    const CCN = await ethers.getContractFactory("CCNCarnival2025");
    const ccn = await CCN.deploy();
    await ccn.deployed();;
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