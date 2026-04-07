// utils
import { tel, mailto } from '@/utils/functions'

// types
interface Props {
    title?: string
    phone?: {
        label: string
        phone: string
    }
    email?: {
        label: string
        url: string
    }
}

export default function Footer({
    title = 'Figma Extractify',
    email = {
        label: 'Email us',
        url: 'info@example.com'
    }
}: Props) {
    return (
        <footer className='bg-stone-100 py-10' data-footer>
            <div className='base-container'>
                <div className='flex md:justify-between flex-col md:flex-row gap-6'>

                    <div>
                        <p className='text-2xl'>
                            {title}
                        </p>
                    </div>

                    <div>
                        <p className='text-base'>
                            {/* mailto: is an external protocol — plain <a> is correct here, not <Link> */}
                            {email?.label} <a className='hover-underline' href={mailto(email?.url)}>{email?.url}</a>
                        </p>
                    </div>

                </div>
            </div>
        </footer>
    )
}