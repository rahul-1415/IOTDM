pragma solidity ^0.5.0;

import "./MerkleProof.sol";
import "./ECRecovery.sol";

contract EntityBase {

    struct Entity {
       
        string data;
    }


    mapping (address => Entity) public ownerToEntity;


    event EntityDataUpdated(address indexed owner, string newData);

    
    function updateEntityData(string memory _data) public {
        ownerToEntity[msg.sender].data = _data;

        emit EntityDataUpdated(msg.sender, _data);
    }
}

contract DeviceBase {

    struct Device {
        
        address owner;

      
        bytes32 identifier;
        

        bytes32 metadataHash;

        bytes32 firmwareHash;

    }
    

    Device[] public devices;


    mapping (address => uint) public ownerDeviceCount;


    event DeviceCreated(uint indexed deviceId, address indexed owner, bytes32 identifier, bytes32 metadataHash, bytes32 firmwareHash);

 
    modifier onlyOwnerOf(uint _deviceId) {
        require(devices[_deviceId].owner == msg.sender, "Only for device owner");
        _;
    }


    function createDevice(bytes32 _identifier, bytes32 _metadataHash, bytes32 _firmwareHash) public returns (uint) {
        Device memory newDevice = Device(msg.sender, _identifier, _metadataHash, _firmwareHash);
        uint deviceId = devices.push(newDevice) - 1;
        ownerDeviceCount[msg.sender]++;

        emit DeviceCreated(deviceId, msg.sender, _identifier, _metadataHash, _firmwareHash);
        return deviceId;
    }
}


contract DeviceHelper is DeviceBase {

    function getDevicesByOwner(address _owner) public view returns (uint[] memory) {
        uint[] memory deviceIds = new uint[](ownerDeviceCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < devices.length; i++) {
            if (devices[i].owner == _owner) {
                deviceIds[counter] = i;
                counter++;
            }
        }
        return deviceIds;
    }


    function isDeviceAnEntity(uint _deviceId) public view returns (bool) {
        return devices[_deviceId].owner == address(uint160(uint256(devices[_deviceId].identifier)));
    }


    function isValidMetadataMember(uint _deviceId, bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verifyProof(_proof, devices[_deviceId].metadataHash, _leaf);
    }


    function isValidFirmwareHash(uint _deviceId, bytes32 _firmwareHash) public view returns (bool) {
        return devices[_deviceId].firmwareHash == _firmwareHash;
    }


    function isValidEthMessage(uint _deviceId, bytes32 _messageHash, bytes memory _signature) public view returns (bool) {
        return ECRecovery.recover(_messageHash, _signature) == address(uint160(uint256(devices[_deviceId].identifier)));
    }
}


contract SignatureBase {
    
    struct Signature {
        // Ethereum address of the signer.
        address signer;

        // ID of device to sign.
        uint deviceId;

        // Using 256 bits ensures no overflow on year 2038 (Unix seconds).
        uint expiryTime;

        // Updates to true once signer decides to revoke signature.
        bool revoked;
    }

   
    Signature[] public signatures;

  
    mapping (uint => uint) public deviceSignatureCount;
    
  
    event DeviceSigned(uint indexed signatureId, uint indexed deviceId, address indexed signer, uint expiryTime);

  
    event SignatureRevoked(uint indexed signatureId, uint indexed deviceId);

  
    modifier notSigned(uint _deviceId) {
        require(deviceSignatureCount[_deviceId] == 0, "Must not be signed");
        _;
    }


    function signDevice(uint _deviceId, uint _expiryTime) public returns (uint) {
        Signature memory signature = Signature(msg.sender, _deviceId, _expiryTime, false);
        uint signatureId = signatures.push(signature) - 1;
        deviceSignatureCount[_deviceId]++;

        emit DeviceSigned(signatureId, _deviceId, msg.sender, _expiryTime);
        return signatureId;
    }


    function revokeSignature(uint _signatureId) public {
        require(signatures[_signatureId].signer == msg.sender, "Only for creator of the signature");
        require(signatures[_signatureId].revoked == false, "Signature mustn't be revoked already");
        Signature storage signature = signatures[_signatureId];
        signature.revoked = true;
        deviceSignatureCount[signature.deviceId]--;

        emit SignatureRevoked(_signatureId, signature.deviceId);
    }
}


contract SignatureHelper is SignatureBase {

    function getActiveSignaturesForDevice(uint _deviceId) public view returns (uint[] memory) {
        uint[] memory signatureIds = new uint[](deviceSignatureCount[_deviceId]);
        uint counter = 0;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i].deviceId == _deviceId && signatures[i].revoked == false) {
                signatureIds[counter] = i;
                counter++;
            }
        }
        return signatureIds;
    }
}


contract DeviceUpdatable is DeviceHelper, SignatureHelper {
   
    event DeviceTransfered(uint indexed deviceId, address oldOwner, address newOwner);
    
  
    event DevicePropertyUpdated(uint indexed deviceId, bytes32 indexed property, bytes32 newValue);

  
    function transferDevice(uint _deviceId, address _to) public onlyOwnerOf(_deviceId) notSigned(_deviceId) {
        address currentOwner = devices[_deviceId].owner;
        devices[_deviceId].owner = _to;
        ownerDeviceCount[msg.sender]--;
        ownerDeviceCount[_to]++;

        emit DeviceTransfered(_deviceId, currentOwner, _to);
    } 

 
    function updateIdentifier(uint _deviceId, bytes32 _newIdentifier) public onlyOwnerOf(_deviceId) notSigned(_deviceId) {
        devices[_deviceId].identifier = _newIdentifier;

        emit DevicePropertyUpdated(_deviceId, "identifier", _newIdentifier);
    }

   
    function updateMetadataHash(uint _deviceId, bytes32 _newMetadataHash) public onlyOwnerOf(_deviceId) notSigned(_deviceId) {
        devices[_deviceId].metadataHash = _newMetadataHash;

        emit DevicePropertyUpdated(_deviceId, "metadata", _newMetadataHash);
    }


    function updateFirmwareHash(uint _deviceId, bytes32 _newFirmwareHash) public onlyOwnerOf(_deviceId) notSigned(_deviceId) {
        devices[_deviceId].firmwareHash = _newFirmwareHash;

        emit DevicePropertyUpdated(_deviceId, "firmware", _newFirmwareHash);
    }
}


contract DeviceManager is EntityBase, DeviceUpdatable {
    
}
