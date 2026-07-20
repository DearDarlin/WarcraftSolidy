// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MoodDiary{

    struct UsersMood{
        string myMood;
        bool haveIEarlyMood;
        uint256 countChangeMyMood;
    }

    mapping(address => UsersMood) private usersMood;

    function writeMood(string memory _mood) public {
        require(bytes(_mood).length > 0 , "Mood can`t be empty!");
        require(!usersMood[msg.sender].haveIEarlyMood, "Mood already exists!");
        usersMood[msg.sender] = UsersMood({
                myMood: _mood,
                haveIEarlyMood: true,
                countChangeMyMood: 0});
        
    }
    
    function changeMood(string memory _mood) public {
        require(usersMood[msg.sender].haveIEarlyMood, "You have not written your mood!");
        require(bytes(_mood).length > 0 , "Mood can`t be empty!");
        usersMood[msg.sender].myMood = _mood;
        usersMood[msg.sender].countChangeMyMood += 1;
    }


    function takeMood() public view returns (string memory){
        require(usersMood[msg.sender].haveIEarlyMood, "You have not write your mood !");
        return usersMood[msg.sender].myMood;
    }

    function clearMood() public{
        require(usersMood[msg.sender].haveIEarlyMood, "No mood to clear!");
        delete usersMood[msg.sender].myMood;
        usersMood[msg.sender].haveIEarlyMood = false;
    }

    function checkHaveIEarlyMood(address _user) public view returns (bool){
        return usersMood[_user].haveIEarlyMood;
    }
    
    function checkCountChangeMyMood(address _user) public view returns (uint256){
        return usersMood[_user].countChangeMyMood;
    }

}