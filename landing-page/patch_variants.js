const fs = require('fs');

const file = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/data/landing-content.ts';
let content = fs.readFileSync(file, 'utf8');

// Add tailVariant to interface
if (!content.includes('tailVariant?:')) {
  content = content.replace(
    'ctaText?: string;',
    'ctaText?: string;\n  tailVariant?: "A" | "B" | "C" | "default";'
  );
}

// Get the main-landing string to copy
const regex = /'main-landing': (\{[\s\S]*?\n\}),\n  'sweet-tooth':/m;
const match = content.match(regex);

if (match) {
  let mainLandingObjStr = match[1];
  
  // Create variants
  let varA = mainLandingObjStr.replace(/\n\}$/, ',\n    "tailVariant": "A"\n}');
  let varB = mainLandingObjStr.replace(/\n\}$/, ',\n    "tailVariant": "B"\n}');
  let varC = mainLandingObjStr.replace(/\n\}$/, ',\n    "tailVariant": "C"\n}');
  
  // Append variants after main-landing
  content = content.replace(
    regex,
    `'main-landing': ${mainLandingObjStr},\n  'variant-a': ${varA},\n  'variant-b': ${varB},\n  'variant-c': ${varC},\n  'sweet-tooth':`
  );
  
  fs.writeFileSync(file, content);
  console.log("Successfully patched landing-content.ts with variants A, B, and C.");
} else {
  console.log("Could not find main-landing block.");
}
