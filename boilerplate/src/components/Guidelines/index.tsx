'use client'

// libraries
import { useState, useEffect } from 'react'
import clsx from 'clsx'

export default function Guidelines() {

	const [isGridVisible, setIsGridVisible] = useState(false)

	useEffect(() => {
		const onKeyDown = (e: KeyboardEvent) => {
			if (e.shiftKey && e.key === 'G') {
				setIsGridVisible(v => !v)
			}
		}

		window.addEventListener('keydown', onKeyDown)
		return () => window.removeEventListener('keydown', onKeyDown)
	}, [])

	return (
		<>
			<div className='flex fixed z-99999999 bottom-2 left-2 p-1 text-xs leading-none bg-black text-white opacity-30 font-sans pointer-events-none before:content-["mob"] before:xs:content-["xs"] before:sm:content-["sm"] before:md:content-["md"] before:lg:content-["lg"] before:xl:content-["xl"] before:2xl:content-["2xl"] before:3xl:content-["3xl"]' />

			<div
				className={clsx(
					'fixed overflow-hidden z-9999 top-0 left-0 w-full h-0 pointer-events-none duration-300 transition-all',
					isGridVisible && 'h-screen'
				)}
			>
				<div className='base-container'>
					<div className='grid grid-cols-4 sm:grid-cols-6 md:grid-cols-12 gap-4'>
						{Array.from({ length: 12 }).map((_, i) => (
							<div key={i}>
								<div className='block w-full h-lvh bg-red-500/20'></div>
							</div>
						))}
					</div>
				</div>
			</div>
		</>
	)
}