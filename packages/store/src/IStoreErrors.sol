// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStoreErrors {
  // Errors include a stringified version of the tableId for easier debugging if cleartext tableIds are used
  error StoreCore_TableAlreadyExists(bytes32 tableId, string tableIdString);
  error StoreCore_TableNotFound(bytes32 tableId, string tableIdString);

  error StoreCore_NotImplemented();
  error StoreCore_NotDynamicField();
  error StoreCore_InvalidStaticDataLength(uint256 expected, uint256 received);
  error StoreCore_InvalidDynamicDataLength(uint256 expected, uint256 received);
  error StoreCore_InvalidKeyNamesLength(uint256 expected, uint256 received);
  error StoreCore_InvalidFieldNamesLength(uint256 expected, uint256 received);
  error StoreCore_InvalidValueSchemaLength(uint256 expected, uint256 received);
  error StoreCore_DataIndexOverflow(uint256 length, uint256 received);
  error StoreCore_InvalidSplice(uint40 startWithinField, uint40 deleteCount, uint40 fieldLength);
}
