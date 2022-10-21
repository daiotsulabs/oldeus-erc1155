// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../eip2981/IERC2981Royalties.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

contract CheckInterface {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    function check2981(address _contract) public view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }
}
