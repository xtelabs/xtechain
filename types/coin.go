package types

import (
	"math/big"

	sdkmath "cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// AttoPhoton defines the default coin denomination used in xtechain in:
	//
	// - Staking parameters: denomination used as stake in the dPoS chain
	// - Mint parameters: denomination minted due to fee distribution rewards
	// - Governance parameters: denomination used for spam prevention in proposal deposits
	// - Crisis parameters: constant fee denomination used for spam prevention to check broken invariant
	// - EVM parameters: denomination used for running EVM state transitions in xtechain.
	AttoPhoton string = "axte"

	// BaseDenomUnit defines the base denomination unit for xte.
	// 1 xte = 1x10^{BaseDenomUnit} axte
	BaseDenomUnit = 18

	// DefaultGasPrice is default gas price for evm transactions
	DefaultGasPrice = 20
)

// PowerReduction defines the default power reduction value for staking
var PowerReduction = sdkmath.NewIntFromBigInt(new(big.Int).Exp(big.NewInt(10), big.NewInt(BaseDenomUnit), nil))

// NewPhotonCoin is a utility function that returns an "axte" coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewPhotonCoin(amount sdkmath.Int) sdk.Coin {
	return sdk.NewCoin(AttoPhoton, amount)
}

// NewPhotonDecCoin is a utility function that returns an "axte" decimal coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewPhotonDecCoin(amount sdkmath.Int) sdk.DecCoin {
	return sdk.NewDecCoin(AttoPhoton, amount)
}

// NewPhotonCoinInt64 is a utility function that returns an "axte" coin with the given int64 amount.
// The function will panic if the provided amount is negative.
func NewPhotonCoinInt64(amount int64) sdk.Coin {
	return sdk.NewInt64Coin(AttoPhoton, amount)
}
