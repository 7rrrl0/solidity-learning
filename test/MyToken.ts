import hre from "hardhat";
import { expect } from "chai";
import { MyToken } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { DECIMALS, MINTING_AMOUNT } from "./constant";

describe("My Token", () => {
  let myTokenC: MyToken;
  let signers: HardhatEthersSigner[];
  beforeEach("should deploy", async () => {
    // 일반 hardhat에는 없음
    signers = await hre.ethers.getSigners();
    myTokenC = await hre.ethers.deployContract("MyToken", [
      "myToken",
      "MT",
      DECIMALS,
      MINTING_AMOUNT,
    ]);
  });
  describe("Basic state value check", () => {
    it("should return name", async () => {
      expect(await myTokenC.name()).equal("myToken");
    });

    it("should return symbol", async () => {
      expect(await myTokenC.symbol()).equal("MT");
    });

    it("should return decimals", async () => {
      expect(await myTokenC.decimals()).equal(DECIMALS);
    });

    it("should return 100 totalSupply", async () => {
      expect(await myTokenC.totalSupply()).equal(
        MINTING_AMOUNT * 10n ** DECIMALS
      );
    });
  });

  describe("Mint", () => {
    it("should return initialSupply + 1MT balance for signer 0", async () => {
      const signer0 = signers[0];
      const oneMt = hre.ethers.parseUnits("1", DECIMALS);
      await myTokenC.mint(oneMt, signer0.address);
      expect(await myTokenC.balanceOf(signer0.address)).equal(
        MINTING_AMOUNT * 10n ** DECIMALS + oneMt
      );
    });

    it("should return or revert when minting infinity", async () => {
      const hacker = signers[2];
      const mintingAgainAmount = hre.ethers.parseUnits("10000", DECIMALS);
      await expect(myTokenC.connect(hacker).mint(mintingAgainAmount, hacker.address)).to.be.revertedWith("You are not authorized to manage this token");
    });
  });

  describe("Transfer", () => {
    it("should have 0.5MT", async () => {
      const signer0 = signers[0];
      const signer1 = signers[1];
      await expect(
        myTokenC.transfer(
          hre.ethers.parseUnits("0.5", DECIMALS),
          signer1.address
        )
      )
        .to.emit(myTokenC, "Transfer")
        .withArgs(
          signer0.address,
          signer1.address,
          hre.ethers.parseUnits("0.5", DECIMALS)
        );

      expect(await myTokenC.balanceOf(signer1.address)).equal(
        hre.ethers.parseUnits("0.5", DECIMALS)
      );
    });

    it("should be reverted with insufficient balance error", async () => {
      const signer1 = signers[1];
      await expect(
        myTokenC.transfer(
          hre.ethers.parseUnits((MINTING_AMOUNT + 1n).toString(), DECIMALS),
          signer1.address
        )
      ).to.be.revertedWith("insufficient balance");
    });
  });
  describe("TransferFrom", () => {
    it("should emit Approval event", async () => {
      const signer1 = signers[1];
      await expect(
        myTokenC.approve(signer1, hre.ethers.parseUnits("10", DECIMALS))
      )
        .to.emit(myTokenC, "Approval")
        .withArgs(signer1, hre.ethers.parseUnits("10", DECIMALS));
    });

    it("should be reverted with insufficient allowance error", async () => {
      const signer0 = signers[0];
      const signer1 = signers[1];
      await expect(
        myTokenC
          .connect(signer1)
          .transferFrom(
            signer0.address,
            signer1.address,
            hre.ethers.parseUnits("1", DECIMALS)
          )
      ).to.be.revertedWith("insufficient allowance");
    });

    it("should allow signer1 to transferFrom signer0 after approval", async () => {
      const signer0 = signers[0];
      const signer1 = signers[1];
      const amount = hre.ethers.parseUnits("5", DECIMALS);

      await expect(myTokenC.connect(signer0).approve(signer1.address, amount))
        .to.emit(myTokenC, "Approval")
        .withArgs(signer1.address, amount);

      await expect(
        myTokenC
          .connect(signer1)
          .transferFrom(signer0.address, signer1.address, amount)
      )
        .to.emit(myTokenC, "Transfer")
        .withArgs(signer0.address, signer1.address, amount);

      const balance0 = await myTokenC.balanceOf(signer0.address);
      const balance1 = await myTokenC.balanceOf(signer1.address);

      expect(balance1).equal(amount);
      expect(balance0).equal(MINTING_AMOUNT * 10n ** DECIMALS - amount);
    });
  });
});
