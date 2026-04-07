'use client'

// libraries
import { useRef, useEffect, useState } from 'react'
import { Fancybox as NativeFancybox, type FancyboxOptions } from '@fancyapps/ui'
import '@fancyapps/ui/dist/fancybox/fancybox.css'
import '@fancyapps/ui/dist/carousel/transitions.css'

interface FancyboxComponentProps {
	delegate?: string
	options?: Partial<FancyboxOptions>
	children: React.ReactNode
}

interface FancyboxHookOptions extends Partial<FancyboxOptions> {
	delegate?: string
}

export default function Fancybox({ delegate = '[data-fancybox]', options = {}, children }: FancyboxComponentProps) {
	const containerRef = useRef<HTMLDivElement>(null)

	useEffect(() => {
		const container = containerRef.current
		if (!container) return

		NativeFancybox.bind(container, delegate, options)

		return () => {
			NativeFancybox.unbind(container)
			NativeFancybox.close()
		}
	}, [delegate, options])

	return (
		<div ref={containerRef}>
			{children}
		</div>
	)
}

// hook version for more advanced use cases
export function useFancybox(options: FancyboxHookOptions = {}) {
	const [root, setRoot] = useState<HTMLElement | null>(null)
	const { delegate = '[data-fancybox]', ...fancyboxOptions } = options

	useEffect(() => {
		if (root) {
			NativeFancybox.bind(root, delegate, fancyboxOptions)
			return () => {
				NativeFancybox.unbind(root)
				NativeFancybox.close()
			}
		}
	}, [root, delegate, fancyboxOptions])

	return [setRoot] as const
}
