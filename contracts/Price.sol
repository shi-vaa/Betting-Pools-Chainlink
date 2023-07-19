pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Price {
    IUniswapV2Router02 public uniswapRouter;

    address internal betszToken;

    address internal usdcToken;

    function getEstimatedbetszforETH(uint256 _eth)
        public
        view
        returns (uint256[] memory)
    {
        return uniswapRouter.getAmountsIn(_eth, getPathForETHtoDAI());
    }

    function getEstimatedETHforUSDC(uint256 usdcAmount)
        public
        view
        returns (uint256[] memory)
    {
        return uniswapRouter.getAmountsIn(usdcAmount, getPathForETHtoUSDC());
    }

    function getEstimatedbetsz(uint256 _usdcAmount) public view returns (uint256) {
        uint256 usdcAmount = getEstimatedETHforUSDC(_usdcAmount)[0];
        return getEstimatedbetszforETH(usdcAmount)[0];
    }

    function getPathForETHtoDAI() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = betszToken;
        path[1] = uniswapRouter.WETH();

        return path;
    }

    function getPathForETHtoUSDC() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = usdcToken;
        path[1] = uniswapRouter.WETH();

        return path;
    }
}
