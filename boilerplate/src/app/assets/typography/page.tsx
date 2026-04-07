export default function Page() {
	const samples = [
		{
			className: 'h1',
			desktop: '70px / 120% (4.375rem / 1.2)',
			mobile: '40px / 120% (2.5rem / 1.2)',
			figma: 'Title/H1 Desktop · Title/H1 Mobile'
		},
		{
			className: 'h2',
			desktop: '40px / 120% (2.5rem / 1.2)',
			mobile: '32px / 120% (2rem / 1.2)',
			figma: 'Title/H2 Desktop · Title/H2 Mobile'
		},
		{
			className: 'body',
			desktop: '20px / 150% (1.25rem / 1.5)',
			mobile: '16px / 160% (1rem / 1.6)',
			figma: 'Body/Body Desktop · Body/Body Mobile'
		},
		{
			className: 'small',
			desktop: '18px / 140% (1.125rem / 1.4)',
			mobile: '14px / 140% (0.875rem / 1.4)',
			figma: 'Body/Small Desktop · Body/Small Mobile'
		}
	]

	return (
		<main className='py-20'>
			<div className='base-container'>
				
				<p className='body smaller mb-10 text-black'>
					Poppins → <code className='smaller'>.h1</code>–<code className='smaller'>.h2</code>,{' '}
					<code className='smaller'>.body</code>. Breakpoint:{' '}
					<code className='smaller'>md</code> (768px).
				</p>

				{samples.map((item, i) => (
					<div
						className='flex flex-col gap-4 mb-10'
						key={i}
					>
						<div className='flex flex-wrap gap-2'>
							{[
								`.${item.className}`,
								`Desktop: ${item.desktop}`,
								`Mobile: ${item.mobile}`,
								item.figma
							].map((label, i2) => (
								<p
									className='bg-gray-200 rounded-sm py-1 px-3 text-sm'
									key={i2}
								>
									{label}
								</p>
							))}
						</div>

						<p className={item.className}>
							Lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam, quos.
						</p>

					</div>
				))}
			</div>
		</main>
	)
}
