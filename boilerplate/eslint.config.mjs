import nextConfig from 'eslint-config-next'
import noUnsanitized from 'eslint-plugin-no-unsanitized'
import security from 'eslint-plugin-security'

const eslintConfig = [
    ...nextConfig,
    {
        plugins: {
            'no-unsanitized': noUnsanitized,
            security,
        },
        rules: {
            // Block dangerouslySetInnerHTML with unsanitized values
            'no-unsanitized/property': 'error',
            'no-unsanitized/method': 'error',
            // Enforce next/image over bare <img> (eslint-config-next ships this as warn — promote to error)
            '@next/next/no-img-element': 'error',
            // General security patterns
            'security/detect-object-injection': 'warn',
            'security/detect-non-literal-regexp': 'warn',
        },
    },
]

export default eslintConfig
