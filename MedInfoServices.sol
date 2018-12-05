pragma solidity ^0.4.18;

contract MedInfoServices{
    string  private owner_name;
    address private owner=0;
    uint256 private fee=0;

    // for patient info permission_CREATED_BY_ORG 
    uint256 constant permission_CREATED_BY_ORG  = 0; //read and write at beginning by orgs
    uint256 constant permission_APPROVED_RW     = 1; // Patient Approve to read and modify
    uint256 constant permission_APPROVED_RO     = 2; // Patient Approve to read only
    uint256 constant permission_REJECTED        = 3; // Patient not allow to access 
    uint256 constant permission_KEEP            = 4; // Patient not allow to access 
    
    // for alarm to log the info
    uint256 constant OK=0;
    uint256 constant ERR=1;
    //indexed keyword only use in event to filter 
    event alarmInfo(
       address indexed _fromsender,
       uint256 errcode,
       string info,
       address indexed _to
    );
    event logReturnAddr(
       address indexed _fromsender,
       address indexed _target,
       address[]  addraddr,
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
    function setFee(uint256 howmuch) public {
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
        uint256 permission; //for letting paitient restrict the access to this documents
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
    PatientsDTB private patientsDTB;
    OrgsDTB private orgsDTB;
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
    //===============For Org DTB==================================
    function updateOrgRegisterInfo(string _orgName) public payable{
        if(msg.value < fee){
            alarmInfo(msg.sender,ERR,"not enough fee");
            return;
        }
        insertOrg(msg.sender,_orgName);
        alarmInfo(msg.sender,OK,"updated ORG");

    }
    function getOrgName(address _orgID) public view returns(string n){
        return orgsDTB.orgMembers[_orgID].name;
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
    //    return  patientsDTB.patientMembers[msg.sender].description;
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
    function getAllPatients() public view  returns(address[] pids){
        if(msg.sender==owner){
            return patientsDTB.patientMembersList;
        }else{
            return;
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
        if(isPatientDocAvailable(_patId,_did)){ // available Documents
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].lastUpdatedbyOrg=_orgId;
            if(_permission!=permission_KEEP){ // keep the old one if permission_KEEP
                 patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission=_permission;
            }
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].description=_description;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].last_utc=block.timestamp;
            alarmInfo(msg.sender,OK,"updated Documents");
        }else{ /*not exist --> create the new one*/
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].lastUpdatedbyOrg=_orgId;
            if(_permission==permission_KEEP){ // kepp the old one
                 patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission=permission_CREATED_BY_ORG;
            }else{
                 patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission=_permission;
            }
         
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].description=_description;
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].last_utc=block.timestamp; 
            patientsDTB.patientMembers[_patId].docs.mapInfos[_did].idx=patientsDTB.patientMembers[_patId].docs.listIdxs.push(_did)-1; 

            //Insert org to patients
            insertOrgsPatientShareTo(_patId,_orgId,permission_KEEP,0);
            alarmInfo(msg.sender,OK,"created new Documents");
        }
    }
    function getPatientsDocCnt(address _patId) private view returns(uint256 v){
        return patientsDTB.patientMembers[_patId].docs.listIdxs.length;
    }
    function getPermissionOrgOfDoc(address _patId,uint256 _did) private view returns(uint256 per){
        return patientsDTB.patientMembers[_patId].docs.mapInfos[_did].permission;
    }
    function getPatientDocs(address _patId) private view returns(uint256[] _did){
         return patientsDTB.patientMembers[_patId].docs.listIdxs;
    }
    //================For OrgsPatientShareTo===============
    function isOrgsPatientShareToAvailable(address _patId, address _orgId) private view returns(bool isOK){
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
    function getOrgsPatientsSharePermission(address _orgId,address _patId) private view returns(uint256 per){
       return patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].permission;
    }
    function getOrgsPatientsShareExpiredTime(address _orgId,address _patId) private view returns(uint utc){
        return patientsDTB.patientMembers[_patId].orgs.mapInfos[_orgId].expired_utc_time;
    }
    //===============For control the workflow==============
    //org always have permission to update their records as created by orgs --> the system will track the time when they update excepting when the patient forbid that
    function orgUpdatePatientDocument(address _patID,uint256 _did,string _description) payable public{
        if(msg.value < fee){
            alarmInfo(msg.sender,ERR,"not enough fee to update new PatientDocuments");
            return;
        }
        if(!isPatAvailable(_patID)){
            alarmInfo(msg.sender,ERR,"patient is not registered yet");
            return;
        }
        uint256 per =getPermissionOrgOfDoc(_patID,_did);
        if((per==permission_REJECTED)&&(per==permission_APPROVED_RO)){
            alarmInfo(msg.sender,ERR,"patient does not allow org to update this doc");
            return;
        }
        
        insertPatientDoc(_patID,_did,msg.sender,permission_KEEP,_description);//keep the previous permission
        alarmInfo(msg.sender,OK,"created new doc for patient");
    }
    function orgGetPatientsDocument(address _patID) public returns (uint256[] _did){
        uint256 per=getOrgsPatientsSharePermission(msg.sender,_patID);
        uint256 utc_expired =getOrgsPatientsShareExpiredTime(msg.sender,_patID);
        if(utc_expired > block.timestamp){
            alarmInfo(msg.sender,ERR,"permission_expired");
            return ;
        }
        if((per== permission_APPROVED_RO)||(per== permission_APPROVED_RW)){
             alarmInfo(msg.sender,OK,"acepted permission");
             return getPatientDocs(_patID);
        }else{
            alarmInfo(msg.sender,ERR,"permission_REJECTED");
            return ;
        }
    }
    function orgGetPatientsDocumentIsReadable(address _patID) public returns (bool isaccepted){
        uint256 per=getOrgsPatientsSharePermission(msg.sender,_patID);
        uint256 utc_expired =getOrgsPatientsShareExpiredTime(msg.sender,_patID);
        if(utc_expired > block.timestamp){
            alarmInfo(msg.sender,ERR,"permission_expired");
            return false;
        }
        if((per== permission_APPROVED_RO)||(per== permission_APPROVED_RW)){
             alarmInfo(msg.sender,OK,"acepted permission");
             return true;
        }else{
            alarmInfo(msg.sender,ERR,"permission_REJECTED");
            return false;
        }
    }
    //only service provider can use this function to approve the request
    function checkPermissionOfOrgsWithPatient(address _ordID,address _patID) public returns(bool isaccepted){
       
            uint256 per=getOrgsPatientsSharePermission(_ordID,_patID);
            uint256 utc_expired =getOrgsPatientsShareExpiredTime(_ordID,_patID);
    
            if((utc_expired < block.timestamp)&&(utc_expired>0)){
                alarmInfo(msg.sender,ERR,"permission_expired");
                return false;
            }
            
            if((per== permission_APPROVED_RO)||(per== permission_APPROVED_RW)){
                 alarmInfo(msg.sender,OK,"acepted permission");
                 return true;
            }else{
                alarmInfo(msg.sender,ERR,"permission_REJECTED");
                return false;
            }
    }
    function serviceProviderCheckPermissionOfOrgsWithPatient(address _ordID,address _patID) public returns(bool isaccepted){
        if(msg.sender==owner){
            uint256 per=getOrgsPatientsSharePermission(_ordID,_patID);
            uint256 utc_expired =getOrgsPatientsShareExpiredTime(_ordID,_patID);
            if(utc_expired > block.timestamp){
                alarmInfo(msg.sender,ERR,"permission_expired");
                return false;
            }
            
            if((per== permission_APPROVED_RO)||(per== permission_APPROVED_RW)){
                 alarmInfo(msg.sender,OK,"acepted permission");
                 return true;
            }else{
                alarmInfo(msg.sender,ERR,"permission_REJECTED");
                return false;
            }
        }else{
            alarmInfo(msg.sender,ERR,"only service provoder can use this function");
            return false;
        }
            
    }
   
    //==============For patient===================
    function patientApproveOrgsPermission(address _orgId,uint256 _permission,uint expired_utc_time) public{
        if(isPatAvailable(msg.sender)){
            insertOrgsPatientShareTo(msg.sender,_orgId,_permission,expired_utc_time);
        }else{
            alarmInfo(msg.sender,ERR,"patient not available");
        }
    }
    function patientGetDesc() public view returns(string v){
        return patientsDTB.patientMembers[msg.sender].description;
    }
    
}