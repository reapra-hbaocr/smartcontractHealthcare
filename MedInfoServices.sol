pragma solidity ^0.4.18;

contract MedInfoServices{
    string  public owner_name;
    address public owner=0;
    uint256 public fee=0;
    

    // for patient info permission_CREATED_BY_ORG 
    uint256 permission_CREATED_BY_ORG  = 0; //read and write at beginning by orgs
    uint256 permission_APPROVED_RW     = 1; // Patient Approve to read and modify
    uint256 permission_APPROVED_RO     = 2; // Patient Approve to read only
    uint256 permission_REJECTED        = 3; // Patient not allow to access 
    uint256 permission_KEEP            = 4; // Patient not allow to access 
    
    // for alarm to log the info
    uint256 constant OK=0;
    uint256 constant ERR=1;
    //indexed keyword only use in event to filter 
    event alarmInfo(
       address indexed _fromsender,
       uint256 errcode,
       string info
    );
    //---------------For service FHIR provider------------------
    // service provider
    function MedInfoServices(string _name,uint256 _fee) public {
        owner = msg.sender;
        owner_name=_name;
        fee=_fee;//80000000000000
    }
    //change the owner of the service provider
    function changeOwnerService(address _to,string _name) public {
        require(msg.sender==owner);
        owner = _to;
        owner_name=_name;
    }
    // withdraw  ETH from this service
    function withdraw(uint256 howmuch) public {
        require(msg.sender==owner);
        msg.sender.transfer(howmuch);
    }
    function setFees(uint256 howmuch) public {
        require(msg.sender==owner);
        fee=howmuch;
    }
    function getFee() view public returns( uint256 v){
        return fee;
    }
    //-----------for DocumentInfos ---------------
    struct DocumentInfo{
        uint256 idx;
        uint256 hashofResult;
        address lastUpdatedbyOrg;
        uint256 permission;
        string description;
        uint last_utc;
    }
    struct Docs{
        uint256[] listIdxs;
        mapping(uint256=>DocumentInfo) mapInfos;
    }
    //--------for Organization OrganizeInfo------------------
    struct OrganizationInfo{
        uint256 idx;
        uint256 permission;
        uint expired_utc_time;
    }
    struct Orgs{
        address[] listIdxs;
        mapping(address=>OrganizationInfo) mapInfos;
    }
    //---------For Organization handle-----------------------
    struct PatientOfOrgInfo{
        uint256 idx;
        uint256 permission;
        string description;
    }
    struct PatientOfOrgs{
        address[] listIdxs;
        mapping(address=>PatientOfOrgInfo) mapInfos;
    }
    //=======================Declare SmartContract Database==========
    struct PIDInfos{
        uint256 idx;
        Docs docs;
        Orgs orgs;
        string description;
    }
    struct OIDInfos{
        uint256 idx;
        PatientOfOrgs patients;
        address orgID;
        string name;
    }
    struct PatientsDTB{
        mapping(address=>PIDInfos) patientMembers;
        address[] patientMembersList;
    }
    struct OrgsDTB{
        mapping(address=>OIDInfos) orgMembers;
        address[] orgMembersList;
    }
    PatientsDTB patientsDTB;
    OrgsDTB orgsDTB;
    function isOrgAvailable(address _orgID) public view returns(bool isOk){
       if(orgsDTB.orgMembersList.length == 0){
           return false;
       }
      return (orgsDTB.orgMembersList[orgsDTB.orgMembers[_orgID].idx] == _orgID);
   }
    function insertOrg(address _orgID,string _name) private {
        if(isOrgAvailable(_orgID)){
            //update new data
            orgsDTB.orgMembers[_orgID].name =_name;
            alarmInfo(msg.sender,OK,"updated OK");
        }else{ 
            //create new records
            orgsDTB.orgMembers[_orgID].name =_name;
            orgsDTB.orgMembers[_orgID].orgID =_orgID;
            orgsDTB.orgMembers[_orgID].idx=orgsDTB.orgMembersList.push(_orgID)-1;
            alarmInfo(msg.sender,OK,"created OK");
        }    
   }
    //===============For Org==================================
    function updateOrgRegisterInfo(string _orgName) public payable{
        if(msg.value < fee){
            alarmInfo(msg.sender,ERR,"not enough fee");
            return;
        }
        insertOrg(msg.sender,_orgName);
    }
    function getOrgName() public view returns(string n){
        return orgsDTB.orgMembers[msg.sender].name;
    }
    function getAllOrgs() public view returns(address[] oIds){
        return orgsDTB.orgMembersList;
    }
    function getPatientsOfOrg() public view returns(address[] pids){
        return orgsDTB.orgMembers[msg.sender].patients.listIdxs;
    }
    
    //=================For patients DTB===================
    function isPatAvailable(address _patId) public view returns(bool isOK) {
        if(patientsDTB.patientMembersList.length == 0){
           return false;
        }
        return (patientsDTB.patientMembersList[patientsDTB.patientMembers[_patId].idx] == _patId);
    }
    function insertPatient(address _patId,string _description) private{
        if(isPatAvailable(_patId)){
             //update new data
            patientsDTB.patientMembers[_patId].description=_description;
            alarmInfo(msg.sender,OK,"available PatinetID"); 
        }else{
            patientsDTB.patientMembers[_patId].description=_description;
            patientsDTB.patientMembers[_patId].idx=patientsDTB.patientMembersList.push(_patId)-1;
            alarmInfo(msg.sender,OK,"created new patient OK");
        }
    }
    function getAllPatients() public returns(address[] pids){
        if(msg.sender==owner){
            return patientsDTB.patientMembersList;
        }else{
            alarmInfo(msg.sender,ERR,"only owner can list all patients");
        }
    }
    function updatePatientsRegisterInfo(string _description) public payable{
        if(msg.value < fee){
            alarmInfo(msg.sender,ERR,"not enough fee to update new patient");
            return;
        }
        insertPatient(msg.sender,_description);
    }
    
    //================For Document========================
    function isPatientDocAvailable(address _patId, uint256 _did) public view returns(bool isOK){
        if(!isPatAvailable(_patId)){
            return false;
        }
        
        if(patientsDTB.patientMembers[_patId].docs.listIdxs.length == 0){
           return false;
        }
        uint256 idx =patientsDTB.patientMembers[_patId].docs.mapInfos[_did].idx;
        return (patientsDTB.patientMembers[_patId].docs.listIdxs[idx]==_did);
    }
    function insertPatientDoc(address _patId, uint256 _did,address _orgId,uint256 _permission,string _description) private {
        if(isPatientDocAvailable(_patId,_did)){
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].lastUpdatedbyOrg=_orgId;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission=_permission;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].description=_description;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].last_utc=block.timestamp;
            alarmInfo(msg.sender,OK,"updated Documents");
        }else{
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].lastUpdatedbyOrg=_orgId;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission=_permission;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].description=_description;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].last_utc=block.timestamp; 
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].idx=patientsDTB.patientMembers[_patId].docs.listIdxs.push(_did)-1; 
            alarmInfo(msg.sender,OK,"created new Documents");
        }
            
        
    }
    function getPatientsDocCnt(address _patId) private view returns(uint256 v){
        return patientsDTB.patientMembers[_patId].docs.listIdxs.length;
    }
    //================For OrgsPatientShareTo===============
    function isOrgsPatientShareToAvailable(address _patId, address _orgId) public view returns(bool isOK){
        if(!isPatAvailable(_patId)){
            return false;
        }
        
        if(patientsDTB.patientMembers[_patId].orgs.listIdxs.length == 0){
           return false;
        }
        uint256 idx =patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].idx;
        return (patientsDTB.patientMembers[_patId].orgs.listIdxs[idx]==_orgId);
    }
    function insertOrgsPatientShareTo(address _patId,address _orgId,uint256 _permission,uint utc_expired) private {
        if(isOrgsPatientShareToAvailable(_patId,_orgId)){
            if(utc_expired>0){
                patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].expired_utc_time=utc_expired;
            }
            if(_permission!=permission_KEEP){
                patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].permission=_permission;
            }
            alarmInfo(msg.sender,OK,"updated Patient share to orgs permission");
        }else{
           if(utc_expired>0){
                patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].expired_utc_time=utc_expired;
            }
            if(_permission!=permission_KEEP){
                patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].permission=_permission;
            }
            patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].idx=patientsDTB.patientMembers[_patId].orgs.listIdxs.push(_orgId)-1; 
            alarmInfo(msg.sender,OK,"updated Patient share to orgs permission");
        }
            
        
    }
    function getOrgsPatientsShareToCnt(address _patId) private view returns(uint256 v){
        return patientsDTB.patientMembers[_patId].orgs.listIdxs.length;
    }
    function getOrgsPatientShareTo(address _patId) private view returns(address[] orgIds){
        return patientsDTB.patientMembers[_patId].orgs.listIdxs;
    }
  
}