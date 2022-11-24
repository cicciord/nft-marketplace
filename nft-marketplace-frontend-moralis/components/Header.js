import { ConnectButton } from "web3uikit"
import Link from "next/link"

export default function Header() {
    return (
        <nav>
            <Link href="/">Marketplace</Link>
            <Link href="/sell-nft">Sell</Link>
            <ConnectButton />
        </nav>
    )
}
