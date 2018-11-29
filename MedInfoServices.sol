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
        address lastUpdatedbyOrg;
        uint256 permission;
        string description;
        string last_utc;
    }
    
    struct Docs{
        uint256[] listIdxs;
        mapping(uint256=>DocumentInfo) mapInfos;
    }
    
    //--------for Organization OrganizeInfo------------------
    struct OrganizationInfo{
        uint256 idx;
        uint256 permission;
        uint256 expired_utc_time;
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
    }
    
    struct OIDInfos{
        uint256 idx;
        PatientOfOrgs patients;
        address orgID;
        string name;
    }
    
    struct MembersDTB{
        mapping(address=>PIDInfos) patientMembers;
        address[] patientMembersList;
    }
    struct OrgsDTB{
        mapping(address=>OIDInfos) orgMembers;
        address[] orgMembersList;
    }
   
    
   MembersDTB membersDTB;
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
   
    // call this function to create(update if existing).
    //  the Tx call this function must come along with ETH in wei 
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
    
   function getOrgPatients() public view returns(address[] pids){
        return orgsDTB.orgMembers[msg.sender].patients.listIdxs;
    }
    
    
    
    // function addOrgsInfo(string _orgName) public payable{
        
    //     if(msg.value < fee){
    //         alarmInfo(msg.sender,ERR,"not enough fee");
    //         return;
    //     }
        
    //     if(orgInfo[msg.sender].orgID==msg.sender){
    //          orgInfo[msg.sender].name=_orgName;
    //          alarmInfo(msg.sender,OK,"updated OK");
    //     }else{
    //         orgInfo[msg.sender].orgID=msg.sender;
    //         orgInfo[msg.sender].name=_orgName;
    //         alarmInfo(msg.sender,OK,"created OK");
    //     }
           
       
        
        
    // }
    
    

    
    
    
    // //---------------For OrganizeInfo------------------
    //  struct OrgInfo{
    //     address orgID;
    //     string name;
    // }
    
    // mapping (address=>OrgInfo) public orgInfo;
    
    // // call this function to create(update if existing).
    // //  the Tx call this function must come along with ETH in wei 
    // function updateOrgRegisterInfos(string _orgName) public payable {
    //     if(msg.value < fee){
    //         alarmInfo(msg.sender,ERR,"not enough fee");
    //         //revert();
    //     }else{
    //         orgInfo[msg.sender].orgID=msg.sender;
    //         orgInfo[msg.sender].name=_orgName;
    //         alarmInfo(msg.sender,OK,"created OK");
    //     }
    // }
    
    // function getOrgName() view public returns(string orgName) {
    //     return orgInfo[msg.sender].name;
    // }
    
    // //only the registered orgID can do that 
    // function createNewMedDocumentFor(address patientId, string reason) public payable {
    //     if(msg.value < fee){
    //         alarmInfo(msg.sender,ERR,"not enough fee to create Document");
    //         //revert();
    //         return;
    //     }
    //     //check 
    //     if( orgInfo[msg.sender].orgID!=msg.sender){
    //         alarmInfo(msg.sender,ERR,"Org have not registered yet");
    //         return;
    //     }
        
    //   //  address
        
        
    //     // else{
    //     //     orgInfo[msg.sender].orgID=msg.sender;
    //     //     orgInfo[msg.sender].name=_orgName;
    //     //      alarmInfo(msg.sender,OK,"createOK");
    //     // }
        
    // }
    
    
    
    
    
    
    
    // //---------------For patient------------------
     
    // struct Patient{
    //     address patId;
    //     address createdById;
    //     string name;
    //     uint256 []recordPointerAddress;
    // }
    
  
    // mapping (address=>Patient) patientInfo;
    
    
    

    
    
    
    
    
}