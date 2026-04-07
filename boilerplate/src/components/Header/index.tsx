// libraries
import Link from 'next/link'
import Image from 'next/image'

// types
interface Props {
    logo?: {
        src: string
        url: string
        alt: string
    }
}

export default function Header({
    logo = {
        src: '/img/logo.svg',
        url: '/',
        alt: 'Figma Extractify'
    }
}: Props) {
    return (
        <section className='py-6 md:py-10 bg-stone-100' data-top-menu>
            <div className='base-container'>
                <div className='flex items-center justify-between gap-4'>
                    <Link href={logo?.url} className='flex w-40 md:w-60'>
                        <figure className='w-full'>
                            <Image
                                src={logo?.src}
                                alt={logo?.alt}
                                width={216}
                                height={40}
                                className='w-full h-auto'
                            />
                        </figure>
                    </Link>
                </div>
            </div>
        </section>
    )
}