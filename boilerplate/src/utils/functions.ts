import DOMPurify from 'isomorphic-dompurify'

// phone
export function tel(str: string) {
	return (
		'tel:' + str.replace(/[^0-9]/g, '')
	)
}

// email
export function mailto(str: string) {
	return (
		'mailto:' + str
	)
}

// limit characters
export function limitCharacters(text: string, limit: number) {
    if (text.length <= limit) {
        return text
    } else {
        return text.slice(0, limit) + '...'
    }
}

// slugify
export function slugify(str: string) {
    return String(str)
        .normalize('NFKD')
        .replace(/[\u0300-\u036f]/g, '')
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9 -]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
}

// first char
export function firstChar(str: string) {
    return str.charAt(0) || ''
}

// get all focusable elements inside the container
export const getFocusableElements = (container: HTMLElement) => {
    return container.querySelectorAll(
        'a, button, input, textarea, select, [tabindex]:not([tabindex="-1"])'
    )
}

// get all focusable elements outside the container
export const getFocusableElementsOutside = (container: HTMLElement | null) => {
    if (!container) {
        return []
    }
    
    const allFocusableElements = document.querySelectorAll(
        'a, button, input, textarea, select, [tabindex]:not([tabindex="-1"])'
    )

    // filter out elements that are inside the container
    return Array.from(allFocusableElements).filter(
        (element) => !container.contains(element)
    )
}

// format the number with thousand separators (spaces)
export function formatNumber(value: number) {
    const num = Math.floor(+value)
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
}

export function capitalizeFirstLetter(str: string) {
    if (!str || typeof str !== 'string') return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// sanitize HTML string before rendering with dangerouslySetInnerHTML
// required for all CMS-sourced, user-supplied, or AI-generated HTML content
export function sanitizeHtml(html: string): string {
    return DOMPurify.sanitize(html)
}
