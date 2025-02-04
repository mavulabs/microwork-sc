const updateJobAddressInSmartContract = async () => {
    if (typeof window !== "undefined" && (window as any).ethereum) {
      try {
        const browserProvider = new ethers.BrowserProvider(
          (window as any).ethereum
        );
        const browserSigner = await browserProvider.getSigner();
        const browserSignerAddress = await browserSigner.getAddress();
        const cusdContract = new ethers.Contract(
          "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1",
          ercAbi,
          browserSigner
        );
        const transferDetails = [
          jobInfoAddress,//from previous call
          amount //rewardAmount*totalTasks
        ];

        const tx = await cusdContract.transfer(transferDetails);
        const txReceipt = await tx.wait();
        console.log(`Tx Hash: ${tx.hash}`);
        
        
        }
      } catch (error) {
        console.log(error);
      }
    }
  };