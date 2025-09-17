"""
ICO dosyasını farklı boyutlarda PNG'ye dönüştürme scripti
"""
from PIL import Image
import os

def convert_ico_to_png(ico_path, output_dir):
    """ICO dosyasını farklı boyutlarda PNG'ye dönüştür"""
    try:
        # ICO dosyasını aç
        img = Image.open(ico_path)
        
        # Farklı boyutlarda kaydet
        sizes = [32, 64, 128, 192, 256, 512]
        
        for size in sizes:
            # Resmi yeniden boyutlandır
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # PNG olarak kaydet
            output_path = os.path.join(output_dir, f"favicon-{size}.png")
            resized.save(output_path, "PNG")
            print(f"✅ {size}x{size} boyutunda favicon oluşturuldu: {output_path}")
            
    except Exception as e:
        print(f"❌ Hata: {e}")

if __name__ == "__main__":
    ico_path = "frontend/assets/logo.ico"
    output_dir = "backend/core_api/static"
    
    if os.path.exists(ico_path):
        convert_ico_to_png(ico_path, output_dir)
        print("🎉 Tüm favicon boyutları başarıyla oluşturuldu!")
    else:
        print(f"❌ ICO dosyası bulunamadı: {ico_path}")
