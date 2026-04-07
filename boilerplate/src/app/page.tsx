import Link from 'next/link'

export default function Home() {
	return (
		<main className='py-10'>
			<div className='base-container'>

				<h1 className='h2' >
					Front-end pages and components
				</h1>

				<p className='body mt-8 mb-16'>
					Press <kbd>shift+g</kbd> to toggle the grid overlay.
				</p>

				{[
					{
						title: 'Assets',
						items: [
							{
								label: 'Typography',
								href: '/assets/typography'
							},
							{
								label: 'Colors',
								href: '/assets/colors'
							}
						]
					},
					{
						title: 'Components',
						items: [
							{
								label: '#',
								href: '#'
							}
						]
					},
					{
						title: 'Pages',
						items: [
							{
								label: '#',
								href: '#'
							}
						]
					}
				].map((item, i) => (
					<div key={i} className='mb-10'>

						<h2 className='h4 mb-4'>
							{item.title}
						</h2>

						<div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4'>
							{item.items.map((subItem, i2) => (
								<Link
									href={subItem.href}
									className='border border-black py-4 px-6 rounded-md transition-colors duration-200 hover:bg-black hover:text-white flex items-center justify-center'
									key={i2}
								>
									{subItem.label}
								</Link>
							))}
						</div>

					</div>
				))}

			</div>
		</main>
	)
}
