// libraries
import type { Metadata } from 'next'
import { Poppins } from 'next/font/google'

// fonts
const bodyFont = Poppins({
	subsets: ['latin'],
	weight: ['400', '600'],
	style: ['normal', 'italic'],
	variable: '--font-body',
	display: 'swap'
})

// metadata
export const metadata: Metadata = {
	title: 'Figma Extractify',
	description: 'Open-source Next.js + Tailwind CSS boilerplate for building isolated, props-driven UI components from Figma.',
	icons: {
		icon: '/img/favicon.png',
	}
}

// css
import '@/assets/css/global.css'

// components
import Header from '@/components/Header'
import Footer from '@/components/Footer'
import Guidelines from '@/components/Guidelines'

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode
}>) {
	return (
		<html lang='en' className={bodyFont.variable} data-scroll-behavior='smooth'>
			<body id='start'>

				<Header />

				<div id='main-content'>
					{children}
				</div>

				<Footer />

				<Guidelines />

			</body>
		</html>
	)
}
