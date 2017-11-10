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
    // could add more complex logic like a list of pre-requisite
    // deliverables
    bool done; // this will be set in the confirmDeliverable function
  }

  struct IAA {
    bytes32 desc; // 32 characters describing contract
    uint startdate; // Unix timestamp of the IAA creation 
    Agency sa; // servicing agency
    Agency ra; // requesting agency
    Deliverable[] deliverables; // list of deliverables
    bool saApproved;
    bool raApproved;
  }

  IAA[] public iaa_list;
  // TODO: add events for IAA addition, modification, delivery

  function addIAA(bytes32 _desc, address _raAddress, address _saAddress,
		  bytes32 _saDesc, bytes32 _raDesc) returns (uint) {
    // require that the requesting agency is the caller of the contract
    require (msg.sender == _raAddress);

    // this function returns the index of the newly created IAA or -1
    // if creation failed
    IAA memory newIAA;
    Agency memory _ra, _sa;
    _ra.Desc = _raDesc;
    _sa.desc = _saDesc;
    _ra.ethAddress = msg.sender; // the requesting agency makes the
				 // addIAA call
    _sa.ethAddress = _saAddress;
    newIAA.desc = _desc;
    newIAA.sa = sa;
    newIAA.ra = ra;
    newIAA.startdate = now;
    newIAA.raApproved = true;
    newIAA.saApproved = false;
    try {
      iaa_list.push(newIAA);
    } catch (e) {
      return false;
    }
    // TODO: send create event
    return true;
  }

  modifier saneIndex(uint i) {
    require (i < iaa_list.length);
    _;
  }

  modifier saneDeliverable(uint i, uint j) {
    require (i < iaa_list.length &&
	     j < iaa_list[i].deliverables.length);
    _;
  }
  
  // approval function
  function approveIAA()
    saneIndex(uint i) {
    if (msg.sender == iaa_list[i].sa.ethAddress) {
      iaa_list[i].saApproved = true;
    }
    if (msg.sender == iaa_list[i].ra.ethAddress) {
      iaa_list[i].raApproved = true;
    }
  }

  // test whether the contract is deployed
  function isDeployed() constant saneIndex(uint i) returns (bool) {
    return iaa_list[i].raApproved && iaa_list[i].saApproved;
  }
  
  // IAA modification: addition and deletion of deliverables
  // add a deliverable to an existing IAA, change approval status
  function addDeliverable(bytes32 _desc, uint _compensation, uint _duration)
    saneIndex(uint i) returns (bool) {
    // only the sa and ra are allowed to add deliverables
    require (msg.sender == iaa_list[i].sa.ethAddress ||
	     msg.sender == iaa_list[i].ra.ethAddress);
    Deliverable memory d;
    d.desc = _desc;
    d.compensation = _compensation;
    d.duration = _duration;
    d.done = false;
    try {
      iaa_list[i].deliverables.push(d);
    } catch (e) {
      return false;
    }
    // require approval by the agency that is not making the change
    if (msg.sender != iaa_list[i].sa.ethAddress) {
      iaa_list[i].saApproved = false;
    }
    if (msg.sender != iaa_list[i].ra.ethAddress) {
      iaa_list[i].raApproved = false;
    }
    return true;
  }

  // remove deliverable, change approval status
  function removeDeliverable() saneDeliverable(uint i, uint j)
    returns (bool) {
    // only the sa and ra are allowed to remove deliverables
    require (msg.sender == iaa_list[i].sa.ethAddress ||
	     msg.sender == iaa_list[i].ra.ethAddress);

    // remove the deliverable
    try {
      uint memory n = iaa_list[i].deliverables.length - 1;
      iaa_list[i].deliverables[j] =
	iaa_list[i].deliverables[n];
      // remove the last element in the deliverables array
      delete iaa_list[i].deliverables[n];
      iaa_list[i].deliverables.length--;
    } catch (e) {
      return false;
    }
    
    // change approval status
    // require approval by the agency that is not making the change
    if (msg.sender != iaa_list[i].sa.ethAddress) {
      iaa_list[i].saApproved = false;
    }
    if (msg.sender != iaa_list[i].ra.ethAddress) {
      iaa_list[i].raApproved = false;
    }
    return true;
  }
    
  // modify deliverable, change approval status
  function modifyDeliverable(bytes32 _desc, uint _compensation,
			     uint _duration) saneDeliverable(uint i, uint j)
    returns (bool) {
    // only the sa and ra are allowed to modify deliverables
    require (msg.sender == iaa_list[i].sa.ethAddress ||
	     msg.sender == iaa_list[i].ra.ethAddress);

    Deliverable memory d;
    d.desc = _desc;
    d.compensation = _compensation;
    d.duration = _duration;
    d.done = false;

    // modify the deliverable
    try {
      iaa_list[i].deliverables[j] = d;
    } catch (e) {
      return false;
    }
    
    // change approval status
    // require approval by the agency that is not making the change
    if (msg.sender != iaa_list[i].sa.ethAddress) {
      iaa_list[i].saApproved = false;
    }
    if (msg.sender != iaa_list[i].ra.ethAddress) {
      iaa_list[i].raApproved = false;
    }
    return true;
  }
    
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

  function confirmDelivery() saneDeliverable(uint i, uint j)
    returns (bool) {
    // require that RA the sender
    require (msg.sender == iaa_list[i].ra.ethAddress);
    // require that the IAA is deployed
    require (iaa_list[i].raApproved && iaa_list[i].saApproved);
    try {
      iaa_list[i].deliverables[j].done = true;
    } catch (e) {
      return false;
    }
    return true;
  }
  
  // IAA deliverables getter function
  function getIAAdeliverables() saneIndex(uint i)
    constant returns (bytes32[], uint[], bool[]) {
    // number of deliverables
    uint num = iaa_list[i].deliverables.length;
    bytes32[] memory descriptions = new bytes32[](num);
    uint[] memory 
}

  
}
