/** @type {import('next').NextConfig} */

const securityHeaders = [
	{
		key: 'X-Frame-Options',
		value: 'SAMEORIGIN',
	},
	{
		key: 'X-Content-Type-Options',
		value: 'nosniff',
	},
	{
		key: 'Referrer-Policy',
		value: 'strict-origin-when-cross-origin',
	},
	{
		key: 'Permissions-Policy',
		value: 'camera=(), microphone=(), geolocation=()',
	},
	// Uncomment for HTTPS production deployments:
	// {
	//   key: 'Strict-Transport-Security',
	//   value: 'max-age=63072000; includeSubDomains; preload',
	// },
	// Tighten CSP based on your actual asset/font/script sources:
	// {
	//   key: 'Content-Security-Policy',
	//   value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; frame-ancestors 'none'",
	// },
]

const nextConfig = {
	output: 'standalone',
	async headers() {
		return [
			{
				source: '/(.*)',
				headers: securityHeaders,
			},
		]
	},
}

export default nextConfig
