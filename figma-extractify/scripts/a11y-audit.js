#!/usr/bin/env node

import { chromium } from 'playwright'
import AxeBuilder from '@axe-core/playwright'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { writeFileSync, mkdirSync } from 'fs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const projectRoot = join(__dirname, '..')
const screenshotsDir = join(projectRoot, '.screenshots')

// Parse CLI arguments
const args = process.argv.slice(2)
if (args.length === 0) {
  console.error('Usage: node scripts/a11y-audit.js <url> [--component=<name>]')
  console.error('Example: node scripts/a11y-audit.js http://localhost:3000/components/hero-banner --component=hero-banner')
  process.exit(2)
}

const url = args[0]
let componentName = null

for (const arg of args.slice(1)) {
  if (arg.startsWith('--component=')) {
    componentName = arg.replace('--component=', '')
  }
}

/**
 * Format violation data for output
 */
function formatViolations(violations) {
  const grouped = {
    critical: [],
    serious: [],
    moderate: [],
    minor: []
  }

  for (const violation of violations) {
    const impact = violation.impact || 'minor'
    if (grouped[impact]) {
      grouped[impact].push({
        id: violation.id,
        impact: violation.impact,
        description: violation.description,
        nodes: violation.nodes.map(node => ({
          html: node.html,
          target: node.target,
          message: node.failureSummary || 'Accessibility violation detected'
        }))
      })
    }
  }

  return grouped
}

/**
 * Main audit function
 */
async function runAudit() {
  let browser = null

  try {
    console.log(`Starting accessibility audit for ${url}...`)

    // Launch browser
    browser = await chromium.launch()
    const context = await browser.newContext()
    const page = await context.newPage()

    // Navigate to URL with timeout
    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 10000 })
    } catch (error) {
      console.error(`Error: Could not navigate to ${url}`)
      console.error(`Details: ${error.message}`)
      process.exit(2)
    }

    // Wait for page to be interactive
    await page.waitForLoadState('domcontentloaded')

    const results = await new AxeBuilder({ page }).analyze()

    // Extract violations from results
    const violations = results.violations || []
    const passes = results.passes ? results.passes.length : 0

    // Format violations by impact
    const grouped = formatViolations(violations)

    // Count violations by impact
    const summary = {
      total_violations: violations.length,
      critical: grouped.critical.length,
      serious: grouped.serious.length,
      moderate: grouped.moderate.length,
      minor: grouped.minor.length
    }

    // Build output object
    const output = {
      url,
      component: componentName,
      timestamp: new Date().toISOString(),
      summary,
      violations: grouped,
      passed: passes
    }

    // Output JSON to stdout
    console.log(JSON.stringify(output, null, 2))

    // Save detailed report if component name provided
    if (componentName) {
      try {
        mkdirSync(screenshotsDir, { recursive: true })
        const reportPath = join(screenshotsDir, `${componentName}-a11y.json`)
        writeFileSync(reportPath, JSON.stringify(output, null, 2))
        console.error(``)
        console.error(`✓ Detailed report saved to: .screenshots/${componentName}-a11y.json`)
      } catch (error) {
        console.error(`Warning: Could not save report to ${screenshotsDir}: ${error.message}`)
      }
    }

    // Print human-readable summary to stderr
    console.error(``)
    console.error(`✓ Accessibility audit for ${url}`)
    console.error(``)
    console.error(`Violations: ${summary.total_violations} total`)

    if (summary.critical > 0) {
      console.error(`  🔴 critical: ${summary.critical}`)
    }
    if (summary.serious > 0) {
      console.error(`  🟠 serious: ${summary.serious}`)
    }
    if (summary.moderate > 0) {
      console.error(`  🟡 moderate: ${summary.moderate}`)
    }
    if (summary.minor > 0) {
      console.error(`  🔵 minor: ${summary.minor}`)
    }

    console.error(``)
    console.error(`✓ Passed: ${passes} rules`)
    console.error(``)

    if (summary.critical > 0 || summary.serious > 0) {
      console.error(`⛔ Action required: Fix ${summary.critical + summary.serious} critical/serious violation(s) before proceeding.`)
      console.error(``)
      await browser.close()
      process.exit(1)
    } else if (summary.moderate > 0) {
      console.error(`⚠️  ${summary.moderate} moderate violation(s) found. Fix if quick, otherwise log in learnings.md`)
      console.error(``)
    }

    await browser.close()
    process.exit(0)
  } catch (error) {
    console.error(`Error during audit: ${error.message}`)
    if (browser) {
      await browser.close()
    }
    process.exit(2)
  }
}

runAudit()
