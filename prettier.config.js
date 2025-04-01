// The values of these options match Prettier v3.x defaults.
// We repeat them here for clarity, and in case they change in the future.
const prettierDefaults = {
  arrowParens: 'always',
  jsxSingleQuote: false,
  printWidth: 80,
  semi: true,
  singleAttributePerLine: false,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: false,
};

module.exports = {
  ...prettierDefaults,

  // Overrides for specific file types
  overrides: [
    {
      files: ['**/*.cts', '**/*.mts', '**/*.ts', '**/*.tsx'],
      options: {
        arrowParens: 'avoid',
        bracketSpacing: false,
        singleQuote: true,
        trailingComma: 'es5',
      },
    },
    {
      files: ['**/*.cjs', '**/*.js', '**/*.mjs', '**/*.jsx'],
      options: {
        bracketSameLine: true,
        bracketSpacing: false,
        embeddedLanguageFormatting: 'auto',
        htmlWhitespaceSensitivity: 'strict',
        quoteProps: 'preserve',
        singleQuote: true,
      },
    },
    {
      files: ['**/*.css', '**/*.sass', '**/*.scss'],
      options: {
        singleQuote: true,
      },
    },
    {
      files: '*.html',
      options: {
        printWidth: 100,
      },
    },
    {
      files: '*.acx.html',
      options: {
        parser: 'angular',
        singleQuote: true,
      },
    },
    {
      files: '*.ng.html',
      options: {
        parser: 'angular',
        singleQuote: true,
        printWidth: 100,
      },
    },
    {
      files: ['**/*.md'],
      options: {
        embeddedLanguageFormatting: 'off',
        proseWrap: 'always',
        // As recommended by the Google Markdown Style Guide
        // https://google.github.io/styleguide/docguide/style.html
        tabWidth: 4,
      },
    },
  ],
};
