declare const abi: [
  {
    inputs: [
      {
        internalType: "contract IModule";
        name: "_coreModule";
        type: "address";
      }
    ];
    stateMutability: "nonpayable";
    type: "constructor";
  },
  {
    anonymous: false;
    inputs: [
      {
        indexed: true;
        internalType: "address";
        name: "newContract";
        type: "address";
      }
    ];
    name: "WorldDeployed";
    type: "event";
  },
  {
    inputs: [];
    name: "coreModule";
    outputs: [
      {
        internalType: "contract IModule";
        name: "";
        type: "address";
      }
    ];
    stateMutability: "view";
    type: "function";
  },
  {
    inputs: [];
    name: "deployWorld";
    outputs: [];
    stateMutability: "nonpayable";
    type: "function";
  },
  {
    inputs: [];
    name: "worldCount";
    outputs: [
      {
        internalType: "uint256";
        name: "";
        type: "uint256";
      }
    ];
    stateMutability: "view";
    type: "function";
  }
];
export default abi;
