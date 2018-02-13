pragma solidity ^0.4.18;


contract RepoIAA {

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

  IAA[] public iaaList;
  // TODO: add events for IAA addition, modification, delivery

  function addIAA(bytes32 _desc, address _saAddress,
		  bytes32 _saDesc, bytes32 _raDesc) public {
    // the requesting agency is the caller of the function; make sure
    // the servicing agency is different
    require(msg.sender != _saAddress);

    // this function returns the true of the newly created IAA or
    // false if creation failed (see above require statement)
    Agency memory _ra;
    Agency memory _sa;
    _ra.desc = _raDesc;
    _sa.desc = _saDesc;
    _ra.ethAddress = msg.sender; // the requesting agency makes the
				 // addIAA call
    _sa.ethAddress = _saAddress;
    IAA memory newIAA;
    newIAA.desc = _desc;
    newIAA.sa = _sa;
    newIAA.ra = _ra;
    newIAA.startdate = now;
    newIAA.raApproved = true;
    newIAA.saApproved = false;
    iaaList.push(newIAA);
    // TODO: send create event
  }

  // approval function
  function approveIAA(uint i) public {
    require(i < iaaList.length);
    if (msg.sender == iaaList[i].sa.ethAddress) {
      iaaList[i].saApproved = true;
    }
    if (msg.sender == iaaList[i].ra.ethAddress) {
      iaaList[i].raApproved = true;
    }
    // set the start date if deployed
    if (isDeployed(i)) {
      iaaList[i].startdate = now;
    }
  }

  // IAA modification: addition and deletion of deliverables
  // add a deliverable to an existing IAA, change approval status
  function addDeliverable(uint i, bytes32 _desc, uint _compensation,
			  uint _duration) public {
    require(i < iaaList.length);
    // only the sa and ra are allowed to add deliverables
    require(msg.sender == iaaList[i].sa.ethAddress ||
	    msg.sender == iaaList[i].ra.ethAddress);
    Deliverable memory d;
    d.desc = _desc;
    d.compensation = _compensation;
    d.duration = _duration; // in seconds
    d.done = false;
    iaaList[i].deliverables.push(d);
    // require approval by the agency that is not making the change
    if (msg.sender != iaaList[i].sa.ethAddress) {
      iaaList[i].saApproved = false;
    }
    if (msg.sender != iaaList[i].ra.ethAddress) {
      iaaList[i].raApproved = false;
    }
  }

  // remove deliverable j from IAA i, change approval status
  function removeDeliverable(uint i, uint j) public {
    // i is IAA index and j is the deliverable index
    require(i < iaaList.length &&
	    j < iaaList[i].deliverables.length);
    // only the sa and ra are allowed to remove deliverables
    require(msg.sender == iaaList[i].sa.ethAddress ||
	    msg.sender == iaaList[i].ra.ethAddress);

    // remove the deliverable
    uint n = iaaList[i].deliverables.length - 1; // last index
    iaaList[i].deliverables[j] = iaaList[i].deliverables[n];
    // remove the last element in the deliverables array
    delete iaaList[i].deliverables[n];
    iaaList[i].deliverables.length--;
    
    // change approval status
    // require approval by the agency that is not making the change
    if (msg.sender != iaaList[i].sa.ethAddress) {
      iaaList[i].saApproved = false;
    }
    if (msg.sender != iaaList[i].ra.ethAddress) {
      iaaList[i].raApproved = false;
    }
  }
    
  // modify deliverable, change approval status
  function modifyDeliverable(uint i, uint j,
			     bytes32 _desc, uint _compensation,
			     uint _duration) public {
    // i is IAA index and j is the deliverable index
    require(i < iaaList.length &&
	    j < iaaList[i].deliverables.length);
    // only the sa and ra are allowed to modify deliverables
    require(msg.sender == iaaList[i].sa.ethAddress ||
	    msg.sender == iaaList[i].ra.ethAddress);

    Deliverable memory d;
    d.desc = _desc;
    d.compensation = _compensation;
    d.duration = _duration;
    d.done = false;

    // modify the deliverable
    iaaList[i].deliverables[j] = d;
    
    // change approval status
    // require approval by the agency that is not making the change
    if (msg.sender != iaaList[i].sa.ethAddress) {
      iaaList[i].saApproved = false;
    }
    if (msg.sender != iaaList[i].ra.ethAddress) {
      iaaList[i].raApproved = false;
    }
  }
    
  function confirmDelivery(uint i, uint j) public {
    // i is IAA index and j is the deliverable index
    require(i < iaaList.length &&
	    j < iaaList[i].deliverables.length);
    // require that RA is the caller
    require(msg.sender == iaaList[i].ra.ethAddress);
    // require that the IAA is deployed
    require(isDeployed(i));
    // require that it has not been too long
    require(now - iaaList[i].startdate <
	    iaaList[i].deliverables[j].duration);
    
    // mark deliverable as done
    iaaList[i].deliverables[j].done = true;
  }

  // return agency descriptions and the IAA description
  function getIAAmetadata(uint i) public constant
    returns (bytes32, bytes32, bytes32) {
    require(i < iaaList.length);
    return(iaaList[i].desc, iaaList[i].ra.desc, iaaList[i].sa.desc);
  }
  
  // IAA deliverables getter function
  function getIAAdeliverables(uint i) public constant
    returns (bytes32[], uint[], uint[], bool[]) {
    require(i < iaaList.length);
    // number of deliverables
    uint num = iaaList[i].deliverables.length;
    bytes32[] memory descriptions = new bytes32[](num);
    uint[] memory durations = new uint[](num);
    uint[] memory compensations = new uint[](num);
    bool[] memory completions = new bool[](num);
    for (uint j = 0; j < num; j++) {
      descriptions[j] = iaaList[i].deliverables[j].desc;
      compensations[j] = iaaList[i].deliverables[j].compensation;
      durations[j] = iaaList[i].deliverables[j].duration;
      completions[j] = iaaList[i].deliverables[j].done;
    }
    return (descriptions, compensations, durations, completions);
  }

  // test whether the contract is deployed
  function isDeployed(uint i) internal constant returns (bool) {
    require(i < iaaList.length);
    return iaaList[i].raApproved && iaaList[i].saApproved;
  }

    function listMatching(address a) internal returns (uint[]) {
    // this function returns a list of IAA indices in which the
    // address of ra or sa matches the input address
    uint num = iaaList.length;
    uint[] storage matchingIAAs;
    for (uint i = 0; i < num; i++) {
      if (iaaList[i].ra.ethAddress == a || iaaList[i].sa.ethAddress == a) {
	matchingIAAs.push(i);
      }
    }
    return matchingIAAs;
  }
}
