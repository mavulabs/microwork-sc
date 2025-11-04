import "hardhat/types/runtime";
import type { HardhatEthersHelpers } from "@nomicfoundation/hardhat-ethers/types";

declare global {
    namespace Chai {
        interface Assertion {
            emit(contract: any, eventName: string): Assertion;
            withArgs(...args: any[]): Assertion;
            revertedWithCustomError(
                contract: any,
                customError: string
            ): Promise<Assertion>;
            reverted(): Promise<Assertion>;
        }
    }
}

declare module "hardhat" {
    export namespace ethers {
        const getSigners: HardhatEthersHelpers["getSigners"];
        const getContractFactory: HardhatEthersHelpers["getContractFactory"];
        const provider: typeof import("hardhat").network.provider;
    }
}
