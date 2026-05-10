import os

src = "src/app/page.tsx"
with open(src, "r") as f:
    content = f.read()

variants = [
    {
        "dir": "src/app/variant1",
        "name": "ezheWEEKa",
        "primary": "#7C3AED",
        "primary_rgba": "rgba(124,58,237,",
        "gradient": "linear-gradient(135deg, #7C3AED 0%, #6D28D9 100%)",
        "bg_top": "#2D3239", 
        "bg_bottom": "linear-gradient(180deg, #1a1d22 0%, #111318 100%)"
    },
    {
        "dir": "src/app/variant2",
        "name": "ejeweeka",
        "primary": "#4C1D95",
        "primary_rgba": "rgba(76,29,149,",
        "gradient": "linear-gradient(135deg, #4C1D95 0%, #3B0764 100%)",
        "bg_top": "#0F0A1A",
        "bg_bottom": "linear-gradient(180deg, #0F0A1A 0%, #000000 100%)"
    },
    {
        "dir": "src/app/variant3",
        "name": "Ежевика",
        "primary": "#9333EA",
        "primary_rgba": "rgba(147,51,234,",
        "gradient": "linear-gradient(135deg, #9333EA 0%, #166534 100%)",
        "bg_top": "#FAFAFA",
        "bg_bottom": "linear-gradient(180deg, #F8FAFC 0%, #F1F5F9 100%)"
    }
]

for v in variants:
    os.makedirs(v["dir"], exist_ok=True)
    new_content = content
    # Replace texts
    new_content = new_content.replace("Health Code", v["name"])
    # Replace orange colors
    new_content = new_content.replace("#F5922B", v["primary"])
    new_content = new_content.replace("rgba(245,146,43,", v["primary_rgba"])
    new_content = new_content.replace("linear-gradient(135deg, #E85D04 0%, #F5922B 50%, #FFB347 100%)", v["gradient"])
    
    # Specifics for Variant 2 (Darker backgrounds)
    if v["dir"] == "src/app/variant2":
        new_content = new_content.replace("#2D3239", v["bg_top"])
        new_content = new_content.replace("linear-gradient(180deg, #1a1d22 0%, #111318 100%)", v["bg_bottom"])
        new_content = new_content.replace("linear-gradient(145deg, #3a3f47 0%, #2D3239 25%, #23272d 50%, #2D3239 75%, #353a41 100%)", "linear-gradient(145deg, #1F1533 0%, #0F0A1A 25%, #0A0611 50%, #0F0A1A 75%, #180F2A 100%)")
        
    # Specifics for Variant 3 (Light organic backgrounds)
    if v["dir"] == "src/app/variant3":
        new_content = new_content.replace("#2D3239", v["bg_top"])
        new_content = new_content.replace("rgba(255,255,255,0.9)", "#0F172A") # Text color
        new_content = new_content.replace("rgba(255,255,255,0.45)", "#475569")
        new_content = new_content.replace("rgba(255,255,255,0.4)", "#64748B")
        new_content = new_content.replace("rgba(255,255,255,0.3)", "#94A3B8")
        new_content = new_content.replace("rgba(255,255,255,0.18)", "rgba(0,0,0,0.18)")
        new_content = new_content.replace("rgba(255,255,255,0.7)", "#0F172A")
        new_content = new_content.replace("text-white", "text-slate-900")
        new_content = new_content.replace("linear-gradient(180deg, #1a1d22 0%, #111318 100%)", v["bg_bottom"])
        new_content = new_content.replace("linear-gradient(145deg, #3a3f47 0%, #2D3239 25%, #23272d 50%, #2D3239 75%, #353a41 100%)", "linear-gradient(145deg, #FFFFFF 0%, #FAFAFA 25%, #F8FAFC 50%, #FAFAFA 75%, #F1F5F9 100%)")
        new_content = new_content.replace("rgba(26,29,35,0.92)", "rgba(255,255,255,0.92)") # Nav background
        new_content = new_content.replace("borderTop: \"1px solid rgba(255,255,255,0.06)\"", "borderTop: \"1px solid rgba(0,0,0,0.06)\"")

    with open(os.path.join(v["dir"], "page.tsx"), "w") as f:
        f.write(new_content)
        
print("Variants created!")
