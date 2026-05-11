import re

# 1. Fix OnboardingScaffold
path1 = 'health_code/lib/shared/widgets/onboarding_scaffold.dart'
with open(path1, 'r') as f: content1 = f.read()

old_header1 = """                  children: [
                    Text(
                      'ejeweeka',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isFromSummary) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go(Routes.o16Summary),
                        child: const Text('← К сводке',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ],
                  ],"""

new_header1 = """                  children: [
                    if (isFromSummary)
                      GestureDetector(
                        onTap: () => context.go(Routes.o16Summary),
                        child: const Text('← К сводке',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    const Spacer(),
                    Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
                  ],"""

content1 = content1.replace(old_header1, new_header1)
with open(path1, 'w') as f: f.write(content1)
print("Fixed scaffold logo")


# 2. Fix o1_country_screen.dart (Logo + autocorrect)
path2 = 'health_code/lib/features/onboarding/presentation/o1_country_screen.dart'
with open(path2, 'r') as f: content2 = f.read()

# Logo
old_logo2 = """          // Логотип
          Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
            child: Text('ejeweeka', style: TextStyle(fontFamily:'Inter', fontSize:15,
              fontWeight:FontWeight.w800, color:AppColors.primary, letterSpacing:-0.3))),"""

new_logo2 = """          // Логотип
          Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
            child: Row(
              children: [
                const Spacer(),
                Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
              ],
            )),"""
content2 = content2.replace(old_logo2, new_logo2)

# Autocorrect for search
old_search2 = """              onChanged: (v) {
                setState(() => _q = v);
                // Autosave immediately for persistence
                ref.read(profileNotifierProvider.notifier).saveField('country_query', v);
              },
              decoration: InputDecoration("""
new_search2 = """              autocorrect: false,
              enableSuggestions: false,
              onChanged: (v) {
                setState(() => _q = v);
                // Autosave immediately for persistence
                ref.read(profileNotifierProvider.notifier).saveField('country_query', v);
              },
              decoration: InputDecoration("""
content2 = content2.replace(old_search2, new_search2)

# Autocorrect for city
old_city2 = """        onChanged: (v) => setState(() => _city = v),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration("""
new_city2 = """        onChanged: (v) => setState(() => _city = v),
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration("""
content2 = content2.replace(old_city2, new_city2)

with open(path2, 'w') as f: f.write(content2)
print("Fixed country screen logo & autocorrect")


# 3. Fix o16_summary_screen.dart
path3 = 'health_code/lib/features/onboarding/presentation/o16_summary_screen.dart'
with open(path3, 'r') as f: content3 = f.read()
old_logo3 = """          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: const Text('ejeweeka', style: TextStyle(fontFamily:'Inter',fontSize:15,fontWeight:FontWeight.w800,color:AppColors.primary)),
          ),"""
new_logo3 = """          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Spacer(),
                Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
              ],
            ),
          ),"""
content3 = content3.replace(old_logo3, new_logo3)
with open(path3, 'w') as f: f.write(content3)
print("Fixed summary screen logo")

# 4. Fix o16_5_plan_breakdown_screen.dart
path4 = 'health_code/lib/features/onboarding/presentation/o16_5_plan_breakdown_screen.dart'
with open(path4, 'r') as f: content4 = f.read()
old_logo4 = """            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('ejeweeka',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3)),
            ),"""
new_logo4 = """            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Spacer(),
                  Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
                ],
              ),
            ),"""
content4 = content4.replace(old_logo4, new_logo4)
with open(path4, 'w') as f: f.write(content4)
print("Fixed plan breakdown logo")

# 5. Fix u16_about_screen.dart
path5 = 'health_code/lib/features/profile/presentation/u16_about_screen.dart'
with open(path5, 'r') as f: content5 = f.read()
old_logo5 = """            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: const Text('ejeweeka',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3)),
            ),"""
new_logo5 = """            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Spacer(),
                  Image.asset('assets/logo/eje-mark-transparent@2x.png', height: 36),
                ],
              ),
            ),"""
content5 = content5.replace(old_logo5, new_logo5)
with open(path5, 'w') as f: f.write(content5)
print("Fixed about screen logo")

