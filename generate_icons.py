#!/usr/bin/env python3
"""
Generate Flutter app icons for all platforms from a base image.
This script creates properly sized icons for Android, iOS, Windows, macOS, and Linux.
"""

from PIL import Image
import os
from pathlib import Path

def generate_icons(source_image_path, output_base_dir='assets/icon'):
    """Generate icon sizes for all platforms."""
    
    if not os.path.exists(source_image_path):
        print(f"Error: Image file not found at {source_image_path}")
        return False
    
    # Create output directory
    os.makedirs(output_base_dir, exist_ok=True)
    
    # Open the source image
    img = Image.open(source_image_path).convert('RGBA')
    
    # Icon sizes for different platforms
    icon_sizes = {
        # Flutter standard icon
        'app_icon.png': 1024,
        
        # Android icons
        'android/mipmap-ldpi/ic_launcher.png': 36,
        'android/mipmap-mdpi/ic_launcher.png': 48,
        'android/mipmap-hdpi/ic_launcher.png': 72,
        'android/mipmap-xhdpi/ic_launcher.png': 96,
        'android/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/mipmap-xxxhdpi/ic_launcher.png': 192,
        
        # iOS icons
        'ios/icon_20_20@1x.png': 20,
        'ios/icon_20_20@2x.png': 40,
        'ios/icon_20_20@3x.png': 60,
        'ios/icon_29_29@1x.png': 29,
        'ios/icon_29_29@2x.png': 58,
        'ios/icon_29_29@3x.png': 87,
        'ios/icon_40_40@1x.png': 40,
        'ios/icon_40_40@2x.png': 80,
        'ios/icon_40_40@3x.png': 120,
        'ios/icon_60_60@2x.png': 120,
        'ios/icon_60_60@3x.png': 180,
        'ios/icon_76_76@1x.png': 76,
        'ios/icon_76_76@2x.png': 152,
        'ios/icon_83.5_83.5@2x.png': 167,
        'ios/icon_1024_1024@1x.png': 1024,
        
        # Windows
        'windows/icon_16_16.png': 16,
        'windows/icon_32_32.png': 32,
        'windows/icon_64_64.png': 64,
        'windows/icon_128_128.png': 128,
        'windows/icon_256_256.png': 256,
        
        # macOS
        'macos/app_icon_16@1x.png': 16,
        'macos/app_icon_16@2x.png': 32,
        'macos/app_icon_32@1x.png': 32,
        'macos/app_icon_32@2x.png': 64,
        'macos/app_icon_128@1x.png': 128,
        'macos/app_icon_128@2x.png': 256,
        'macos/app_icon_256@1x.png': 256,
        'macos/app_icon_256@2x.png': 512,
        'macos/app_icon_512@1x.png': 512,
        'macos/app_icon_512@2x.png': 1024,
        
        # Linux
        'linux/icon_16x16.png': 16,
        'linux/icon_32x32.png': 32,
        'linux/icon_64x64.png': 64,
        'linux/icon_128x128.png': 128,
        'linux/icon_256x256.png': 256,
    }
    
    # Generate each icon size
    for filename, size in icon_sizes.items():
        output_path = os.path.join(output_base_dir, filename)
        output_dir = os.path.dirname(output_path)
        
        # Create subdirectories
        os.makedirs(output_dir, exist_ok=True)
        
        # Resize and save
        resized_img = img.resize((size, size), Image.LANCZOS)
        resized_img.save(output_path, 'PNG')
        print(f"Generated: {filename} ({size}x{size})")
    
    print(f"\nAll icons generated successfully in: {output_base_dir}")
    return True

if __name__ == '__main__':
    # Change to script directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    source_image = 'assets/icon/app_icon.png'
    
    print("🚀 Hustle App Icon Generator")
    print("=" * 50)
    
    if not os.path.exists(source_image):
        print(f"\nPlease save your icon image as: {source_image}")
        print("Supported formats: PNG, JPG, SVG (will be converted to PNG)")
    else:
        success = generate_icons(source_image)
        if success:
            print("\n✅ Run 'flutter pub get' and 'fluttergen' to apply icons")
