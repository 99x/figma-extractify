// libraries
import clsx from 'clsx'

const baseColors = [
	{
		figmaName: 'Color / Green - #E0FFE6',
		token: 'green',
		label: 'Green',
		hex: '#E0FFE6',
		bg: 'bg-green',
		text: 'text-green'
	},
	{
		figmaName: 'Color / Black - #000000',
		token: 'pure-black',
		label: 'Black',
		hex: '#000000',
		bg: 'bg-pure-black',
		text: 'text-pure-black'
	}
] as const

export default function Page() {
	return (
		<main className='py-20'>
			<div className='base-container'>

				<h1 className='text-4xl font-medium mb-4'>
					Colors
				</h1>

				<div className='flex flex-col gap-2 text-black mb-10'>

					<p className='text-30 font-semibold leading-normal'>
						Base colors
					</p>

					<p className='text-20 leading-normal'>
						Black is used on text, most icons, and as background color on some elements.
						White is used as a background color on the page.
						Green is the main color for link, buttons and etc.
					</p>

				</div>

				<div className='grid sm:grid-cols-2 lg:grid-cols-4 gap-10'>
					{baseColors.map((item) => (
						<div
							className='flex flex-col gap-2'
							key={item.token}
						>

							<div
								className={clsx(
									'block w-full h-40 rounded-md border border-gray-200',
									item.bg
								)}
							/>

							<p className='text-24 font-normal leading-normal mt-2'>
								{item.label}
							</p>

							<p className='text-24 font-normal leading-normal'>
								{item.hex}
							</p>

							<p className='text-16 text-gray-600 break-all max-w-full'>
								--color-{item.token}
							</p>

							<div className='flex flex-wrap gap-2 mt-2'>
								{[
									item.bg,
									item.text,
									item.hex
								].map((line) => (
									<p
										className='block w-fit py-1 px-5 bg-gray-100 rounded-4xl text-sm'
										key={line}
									>
										{line}
									</p>
								))}
							</div>
						</div>
					))}
				</div>

			</div>
		</main>
	)
}
