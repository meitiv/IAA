pragma solidity 0.4.21;
pragma experimental "v0.5.0";


library IterableMap {
    struct Agency {
    bytes32 desc; 
    address ethAddress;
  }

  struct Deliverable {
    bytes32 desc;       // 32 charater deliverble description
    uint compensation;  // fee for service/product
    uint duration;      // how long this deliverable should take
    bool done;          // this will be set in the confirmDeliverable function
  }

  struct IAA {
    bytes32 desc;       // 32 characters describing contract
    uint256 startdate;  // Unix timestamp of the IAA creation 
    Agency sa;          // servicing agency
    Agency ra;          // requesting agency
    DeliverablesMap deliverables;
    bool saApproved;
    bool raApproved;
  }
  
  struct DeliverablesMap {
     mapping(bytes32 => IndexDeliverables) data;
     KeyFlag[] keys;
     uint size;
  }
  
  struct IndexDeliverables { uint keyIndex; Deliverable deliverable; }
  
  struct IAAMap
  {
    mapping(bytes32 => IndexValue) data;
    KeyFlag[] keys;
    uint size;
  } 
  
  struct IndexValue { uint keyIndex; IAA iaa; }
  struct KeyFlag { bytes32 key; bool deleted; }
  
  //*******************************************************************************************************//
  //Map utilities
  //*******************************************************************************************************//
  
  function insertIAA(IAAMap storage self, bytes32 iaaKey, IAA value) internal returns (bool replaced) 
  {
    uint keyIndex = self.data[iaaKey].keyIndex;
    self.data[iaaKey].iaa.desc       = value.desc;
    self.data[iaaKey].iaa.startdate  = value.startdate;
    self.data[iaaKey].iaa.sa         = value.sa;
    self.data[iaaKey].iaa.ra         = value.ra;
    self.data[iaaKey].iaa.saApproved = value.saApproved;
    self.data[iaaKey].iaa.raApproved = value.raApproved;
    if (keyIndex > 0)
      return true;
    else
    {
      keyIndex = self.keys.length++;
      self.data[iaaKey].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = iaaKey;
      self.keys[keyIndex].deleted = false;
      self.size++;
      return false;
    }
  }
  
  function removeIAA(IAAMap storage self, bytes32 key) internal returns (bool success) 
  {
    uint keyIndex = self.data[key].keyIndex;
    if (keyIndex == 0)
      return false;
    deleteIAADeliverables(self, key);
    delete self.data[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  
  function deleteIAADeliverables(IAAMap storage self, bytes32 iaaKey) internal 
  {
    bytes32 deliverableKey;
    IterableMap.Deliverable memory value;
    for (uint256 i = iterateStartDeliverable(self, iaaKey); 
      iterateValidDeliverable(self, i, iaaKey); 
      i = iterateNextDeliverable(self, i, iaaKey)) 
    { 
      (deliverableKey, value) = iterateGetDeliverable(self, i, iaaKey);
      delete self.data[iaaKey].iaa.deliverables.data[deliverableKey];
    }  
    delete self.data[iaaKey].iaa.deliverables;
  }
  
  function containsIAA(IAAMap storage self, bytes32 key) internal view returns (bool) 
  {
    return self.data[key].keyIndex > 0;
  }
  
  function insertDeliverable(IAAMap storage self, bytes32 iaaKey, bytes32 deliverableKey, Deliverable value) 
    internal 
    returns (bool replaced) 
  {
    uint keyIndex = self.data[iaaKey].iaa.deliverables.data[deliverableKey].keyIndex;
    self.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.desc         = value.desc;
    self.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.compensation = value.compensation;
    self.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.duration     = value.duration;
    self.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.done         = value.done;
    if (keyIndex > 0)
      return true;
    else
    {
      keyIndex = self.data[iaaKey].iaa.deliverables.keys.length++;
      self.data[iaaKey].iaa.deliverables.data[deliverableKey].keyIndex = keyIndex + 1;
      self.data[iaaKey].iaa.deliverables.keys[keyIndex].key = deliverableKey;
      self.data[iaaKey].iaa.deliverables.keys[keyIndex].deleted = false;
      self.data[iaaKey].iaa.deliverables.size++;
      return false;
    }
  }
   
  function removeDeliverable(IAAMap storage self, bytes32 iaaKey, bytes32 deliverableKey) 
    internal 
    returns (bool success) 
  {
    uint keyIndex = self.data[iaaKey].iaa.deliverables.data[deliverableKey].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.data[iaaKey].iaa.deliverables.data[deliverableKey];
    self.data[iaaKey].iaa.deliverables.keys[keyIndex-1].deleted = true;
    self.data[iaaKey].iaa.deliverables.size --;
  }
  
  function containsDeliverable(IAAMap storage self, bytes32 iaaKey, bytes32 deliverableKey) 
    internal 
    view 
    returns (bool) 
  {
    return self.data[iaaKey].iaa.deliverables.data[deliverableKey].keyIndex > 0;
  }
  
  //*******************************************************************************************************//
  //Map Iterator functions - IAA
  //*******************************************************************************************************//
  
  function iterateStart(IAAMap storage self) internal view returns (uint keyIndex) {
    return iterateNext(self, uint(-1));
  }
  
  function iterateValid(IAAMap storage self, uint keyIndex) internal view returns (bool) {
    return keyIndex < self.keys.length;
  }
  
  function iterateNext(IAAMap storage self, uint keyIndex) internal view returns (uint r_keyIndex) {
    keyIndex++;
    while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  
  function iterateGet(IAAMap storage self, uint keyIndex) internal view returns (bytes32 key, IAA value) {
    key = self.keys[keyIndex].key;
    value = self.data[key].iaa;
  }
  
  //*******************************************************************************************************//
  //Internal Map Iterator functions - Deliverables
  //*******************************************************************************************************//
  
  function iterateStartDeliverable(IAAMap storage self, bytes32 iaaKey) 
    internal 
    view 
    returns (uint keyIndex) 
  {
    return iterateNextDeliverable(self, uint(-1), iaaKey);
  } 
  
  function iterateValidDeliverable(IAAMap storage self, uint keyIndex, bytes32 iaaKey) 
    internal 
    view 
    returns (bool) 
  {
    return keyIndex < self.data[iaaKey].iaa.deliverables.keys.length;
  }
  
  function iterateNextDeliverable(IAAMap storage self, uint keyIndex, bytes32 iaaKey) 
    internal 
    view 
    returns (uint r_keyIndex) 
  {
    keyIndex++;
    while (keyIndex < self.data[iaaKey].iaa.deliverables.keys.length 
      && self.data[iaaKey].iaa.deliverables.keys[keyIndex].deleted)
      keyIndex++;
    return keyIndex;
  }
  
  function iterateGetDeliverable(IAAMap storage self, uint keyIndex, bytes32 iaaKey) 
    internal 
    view 
    returns (bytes32 key, Deliverable value) 
  {
    key = self.data[iaaKey].iaa.deliverables.keys[keyIndex].key;
    value = self.data[iaaKey].iaa.deliverables.data[key].deliverable;
  }
}


contract RepoIAA {
  using IterableMap for IterableMap.IAAMap;
  address public requestingAgency;
  
  enum ActiveState { Active, Inactive }
  ActiveState state = ActiveState.Active;

  IterableMap.IAAMap iaaData;  
  
  //*******************************************************************************************************//
  //Events
  //*******************************************************************************************************//
  
  event LogState(
    ActiveState state
  );
  
  event LogNewIAA(
    bytes32 key,
    bytes32 desc,
    bytes32 saDesc,
    address saAddress,
    bytes32 raDesc,
    address raAddress
  );
  
  event LogIAADeliverables(
    bytes32[] descriptions,
    uint256[] compensations,
    uint256[] durations,
    bool[]    completions
  );
  
  event LogIAAMetaData(
    bytes32 IAADesc,
    bytes32 RADesc,
    bytes32 SADesc
  );
  
  //*******************************************************************************************************//
  //Modifiers
  //*******************************************************************************************************//
  
  modifier isActiveMod() {
      require(state == ActiveState.Active);
      _;
  }
  
  modifier containsIAAMod(bytes32 iaaKey) {
      require(iaaData.containsIAA(iaaKey));
      _;
  }
  
  modifier containsDeliverableMod(bytes32 iaaKey, bytes32 deliverableKey) {
      require(iaaData.containsDeliverable(iaaKey, deliverableKey));
      _;
  }
  
  modifier isSAorRA(bytes32 iaaKey) {
      require(msg.sender == iaaData.data[iaaKey].iaa.sa.ethAddress ||
        msg.sender == iaaData.data[iaaKey].iaa.ra.ethAddress);
      _;
  }
  
  modifier resetApproval(bytes32 iaaKey) {
      _;
    if (msg.sender != iaaData.data[iaaKey].iaa.sa.ethAddress)  
      iaaData.data[iaaKey].iaa.saApproved = false; 
    if (msg.sender != iaaData.data[iaaKey].iaa.ra.ethAddress)  
      iaaData.data[iaaKey].iaa.raApproved = false; 
  }
  
  //*******************************************************************************************************//
  //Public Functions
  //*******************************************************************************************************//
  
  function RepoIAA() public {
      requestingAgency = msg.sender;
  }
  
  function toggleDeployment() public  {
    require(msg.sender == requestingAgency);
    if (state == ActiveState.Active)
        state = ActiveState.Inactive;
    else 
        state = ActiveState.Active;
  }

  function createIAA(bytes32 iaaKey, bytes32 _desc, address _saAddress, 
    bytes32 _saDesc, bytes32 _raDesc) public isActiveMod()
  { 
    require(msg.sender == requestingAgency); //reqire caller is the initial requesting agency

    IterableMap.Agency memory ra;
    IterableMap.Agency memory sa; 
    ra.desc = _raDesc; 
    sa.desc = _saDesc; 
    ra.ethAddress = msg.sender; 
    sa.ethAddress = _saAddress; 
    IterableMap.IAA memory newIAA; 
    newIAA.desc = _desc; 
    newIAA.sa = sa; 
    newIAA.ra = ra; 
    newIAA.startdate = now; 
    newIAA.raApproved = true; 
    newIAA.saApproved = false;
    iaaData.insertIAA(iaaKey, newIAA);
    
    emit LogNewIAA(iaaKey, iaaData.data[iaaKey].iaa.desc,
        iaaData.data[iaaKey].iaa.sa.desc, iaaData.data[iaaKey].iaa.sa.ethAddress,
        iaaData.data[iaaKey].iaa.ra.desc, iaaData.data[iaaKey].iaa.ra.ethAddress);
  }
  
  function deleteIAA(bytes32 iaaKey) public isActiveMod() isSAorRA(iaaKey) {
    iaaData.removeIAA(iaaKey);
  }
  
  function approveIAA(bytes32 iaaKey) public isActiveMod() containsIAAMod(iaaKey) { 
    if (msg.sender == iaaData.data[iaaKey].iaa.sa.ethAddress)
      iaaData.data[iaaKey].iaa.saApproved = true; 
    if (msg.sender == iaaData.data[iaaKey].iaa.ra.ethAddress) 
      iaaData.data[iaaKey].iaa.raApproved = true; 
    if (isDeployed(iaaKey))
      iaaData.data[iaaKey].iaa.startdate = now; //current block timestamp, not realtime
  }
  
  function createDeliverable(bytes32 iaaKey, bytes32 _desc, uint _compensation, uint _duration) public
    isActiveMod()
    containsIAAMod(iaaKey)
    isSAorRA(iaaKey)
    resetApproval(iaaKey)
  {
    IterableMap.Deliverable memory d; 
    d.desc = _desc; 
    d.compensation = _compensation; 
    d.duration = _duration; // in seconds 
    d.done = false; 
    iaaData.insertDeliverable(iaaKey, _desc, d);
  }
  
  function deleteDeliverable(bytes32 iaaKey, bytes32 deliverableKey) public isActiveMod() isSAorRA(iaaKey) {
    iaaData.removeDeliverable(iaaKey, deliverableKey);
  }
  
  function updateDeliverable(bytes32 iaaKey, bytes32 deliverableKey, 
    bytes32 _desc, uint _compensation, uint _duration) public 
    containsIAAMod(iaaKey) 
    containsDeliverableMod(iaaKey, deliverableKey) 
    isSAorRA(iaaKey) 
    resetApproval(iaaKey) 
  { 
    IterableMap.Deliverable memory d; 
    d.desc = _desc; 
    d.compensation = _compensation; 
    d.duration = _duration; 
    d.done = false; 
    iaaData.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable = d; 
  }
  
  function confirmDelivery(bytes32 iaaKey, bytes32 deliverableKey) public 
    isActiveMod()
    containsIAAMod(iaaKey) 
    containsDeliverableMod(iaaKey, deliverableKey) 
  { 
    require(msg.sender == iaaData.data[iaaKey].iaa.ra.ethAddress);  // require that RA is the caller, 
    require(isDeployed(iaaKey));                                    //              the IAA is deployed,
    require(now - iaaData.data[iaaKey].iaa.startdate <              //              it has not been too long 
        iaaData.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.duration); 
    
    iaaData.data[iaaKey].iaa.deliverables.data[deliverableKey].deliverable.done = true; 
  } 
  
  //*******************************************************************************************************//
  //Emit Functions
  //*******************************************************************************************************//
  
  function emitIAAMetaData(bytes32 iaaKey) public isActiveMod() containsIAAMod(iaaKey) { 
    emit LogIAAMetaData(
        iaaData.data[iaaKey].iaa.desc,
        iaaData.data[iaaKey].iaa.sa.desc,
        iaaData.data[iaaKey].iaa.ra.desc
    ); 
  } 
  
  function emitIAADeliverables(bytes32 iaaKey) public isActiveMod() containsIAAMod(iaaKey) { 
    uint num = iaaData.data[iaaKey].iaa.deliverables.size; 
    bytes32[] memory descriptions = new bytes32[](num);
    uint[] memory durations = new uint[](num);
    uint[] memory compensations = new uint[](num);
    bool[] memory completions = new bool[](num);
    uint16 counter = 0;
    bytes32 deliverableKey;
    IterableMap.Deliverable memory value;
    for (uint256 i = iaaData.iterateStartDeliverable(iaaKey); 
      iaaData.iterateValidDeliverable(i, iaaKey); 
      i = iaaData.iterateNextDeliverable(i, iaaKey)) 
    { 
      (deliverableKey, value) = iaaData.iterateGetDeliverable(i, iaaKey);
      descriptions[counter] = value.desc;
      compensations[counter] = value.compensation;
      durations[counter] = value.duration;
      completions[counter] = value.done;
      counter++;
    }
    
    emit LogIAADeliverables(descriptions, compensations, durations, completions); 
  } 
  
  function emitState() public {
    emit LogState(state);
  }
  
  //*******************************************************************************************************//
  //Internal Functions
  //*******************************************************************************************************//
  
  //unused and untested
  function listMatching(address a) internal view returns (uint[]) { 
    uint num = iaaData.size;
    uint[] memory matchingIAAs = new uint[](num);
    bytes32 key;
    IterableMap.IAA memory value;
    for (uint256 i = iaaData.iterateStart(); iaaData.iterateValid(i); i = iaaData.iterateNext(i)) { 
      (key, value) = iaaData.iterateGet(i);
      if (value.sa.ethAddress == a || value.ra.ethAddress == a) 
        matchingIAAs[i] = 1;
      else
      matchingIAAs[i] = 0;
    } 
    return matchingIAAs; 
  } 
  
  function isDeployed(bytes32 iaaKey) internal containsIAAMod(iaaKey)  view returns (bool) { 
    return iaaData.data[iaaKey].iaa.saApproved && iaaData.data[iaaKey].iaa.raApproved; 
  }
}