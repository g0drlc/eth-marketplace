const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = ethers;

const SECONDS_IN_DAY = 86400;

const formatEther = (value, precision = 4) => {
	const ethValue = ethers.utils.formatEther(value);
	const factor = Math.pow(10, precision);
	return (Math.floor(ethValue * factor) / factor).toString();
}

describe("Marketplace contract", function () {
	beforeEach(async function () {
		const SeedToken = await ethers.getContractFactory("SeedToken");
		const Marketplace = await ethers.getContractFactory("Marketplace");

		this.signers = await ethers.getSigners();
		this.deployer = this.signers[0];
		this.alice = this.signers[1];
		this.bunner = this.signers[2];
		this.bob = this.signers[3];

		this.seedToken = await SeedToken.deploy(this.deployer.address, this.deployer.address);
		await this.seedToken.deployed();

		this.marketplace = await Marketplace.deploy(this.seedToken.address);
		await this.marketplace.deployed();

		const allow = ethers.utils.parseUnits("100000", "ether");
		this.seedToken.approve(this.marketplace.address, allow);

		const ethersToWei = ethers.utils.parseUnits("100", "ether");
		await this.seedToken.mint(this.deployer.address, ethersToWei);
  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
		it("should revert with insufficient cost", async function () {
			const quantity = ethers.utils.parseUnits("100", "ether");
			const price = ethers.utils.parseUnits("0.4", "ether");
			const cost = ethers.utils.parseUnits("10", "ether");
			await expect(
        this.marketplace.addBuyOrder(quantity, price, 0, { value: cost })
      ).to.be.revertedWith("Insufficient cost");
		}),

		it("should be success to add buy-order", async function () {
			const quantity = ethers.utils.parseUnits("100", "ether");
			const price = ethers.utils.parseUnits("0.4", "ether");
			const cost = ethers.utils.parseUnits("40", "ether");
			await this.marketplace.addBuyOrder(quantity, price, 0, { value: cost });
			
			const orders = await this.marketplace.getOrders(this.deployer.address);
			await expect(orders.length).to.eq(1);

			const order = orders[0];
			await expect(order.quantity).to.eq(quantity);
			await expect(order.orderType).to.eq(0);
			await expect(formatEther(order.price)).to.eql("0.4");
    });

		it("should revert with insufficient cost", async function () {
			const quantity = ethers.utils.parseUnits("10000", "ether");
			const price = ethers.utils.parseUnits("0.1", "ether");
			await expect(
        this.marketplace.addSellOrder(quantity, price, 0)
      ).to.be.revertedWith("Insufficient token");
		}),

		it("should be success to add sell-order", async function () {
			const quantity = ethers.utils.parseUnits("10", "ether");
			const price = ethers.utils.parseUnits("0.1", "ether");
			await this.marketplace.addSellOrder(quantity, price, 0);
			
			const orders = await this.marketplace.getOrders(this.deployer.address);
			await expect(orders.length).to.eq(1);

			const order = orders[0];
			await expect(order.quantity).to.eq(quantity);
			await expect(order.orderType).to.eq(1);
			await expect(formatEther(order.price)).to.eql("0.1");
    });
  });
});