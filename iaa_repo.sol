pragma solidity ^0.4.18;

contract IAA_repo {

  struct Agency {
    bytes32 desc; // agency description
    address ethAddress; 
  }

  struct Deliverable {
    bytes32 desc; // 32 charater deliverble description
    uint compensation; // fee for service/product
    uint duration; // how long this deliverable should take
    // could add more complex logic like a deliverable depenency graph
    bool done; // this will be set in the confirmDeliverable function
  }

  struct IAA {
    bytes32 desc; // 32 characters describing contract
    uint startdate; // Unix timestamp of the IAA creation 
    Agency sa; // servicing agency
    Agency ra; // requesting agency
    Deliverable[] deliverables; // list of deliverables
    bool deployed;
  }

  IAA[] public iaa_list;

  function addIAA(bytes32 _desc, address _raAddress, address _saAddress,
		  bytes32 _saDesc, bytes32 _raDesc) returns (uint) {
    // require that the requesting agency is the caller of the contract
    require (msg.sender == _raAddress);

    // this function returns the index of the newly created IAA or -1
    // if creation failed
    IAA memory newIAA;
    Agency memory _ra, _sa;
    _ra.desc = _raDesc;
    _sa.desc = _saDesc;
    _ra.ethAddress = msg.sender; // the requesting agency makes the
				 // addIAA call
    _sa.ethAddress = _saAddress;
    newIAA.desc = _desc;
    newIAA.sa = sa;
    newIAA.ra = ra;
    newIAA.startdate = now;
    newIAA.deployed = false;
    try {
      iaa_list.push(newIAA);
    } catch (e) {
      return false;
    }
    // TODO: implement Events
    return true;
  }

  // the servicing agency has to approve the IAA for it to be deployed
  function deployIAA(uint i) returns (bool) {
    uint memory num = iaa_list.length;
    if (i < 0 || i >= num) return false;
    if (msg.sender == iaa_list[i].sa.ethAddress) {
      iaa_list[i].deployed = true;
      return true;
    }
    return false;
  }

  // add a deliverable to an existing IAA, mark it as not deployed.

  function listMatching(address a) constant returns (uint[]) {
    // this function returns a list of IAA indices in which the
    // ra or the sa matches the input address
    uint num = iaa_list.length;
    uint[] memory matchingIAAs = new uint[](num);
    for (uint i = 0; i < num; i++) {
      if (iaa_list[i].ra.ethAddress == a || iaa_list[i].sa.ethAddress == a) {
	matchingIAAs.push(i);
      }
    }
    return matchingIAAs;
  }

  function confirmDelivery(uint iaaIndex, uint deliverableIndex) returns (bool) {

  }
  
  // IAA status reporter function
  function iaaStatusReport(uint i) constant returns (bytes32[], uint[], bool[]) {
    // number of deliverables
    uint num = iaa_list[i].deliverables.length;
    bytes32[] memory descriptions = new bytes32[](num);
    uint[] memory 
}

  
}
