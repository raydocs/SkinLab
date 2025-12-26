#!/usr/bin/env python3
"""
转换 extract-data-2025-12-25.json 到 SkinLab 格式

将抓取的产品数据转换为符合 SkinLab Product 模型的格式
"""

import json
import re
from typing import Dict, List, Any

# 产品分类映射
CATEGORY_MAPPING = {
    'cleanser': ['cleanser', 'cleansing', 'face wash', 'facial cleanser', 'mousse', 'cream-to-foam'],
    'toner': ['toner', 'essence', 'lotion p50', 'exfoliating toner'],
    'serum': ['serum', 'treatment', 'oil', 'facial oil', 'elixir', 'dew drops', 'boosters'],
    'moisturizer': ['moisturizer', 'cream', 'lotion', 'emulsion', 'gel', 'hydrating'],
    'sunscreen': ['sunscreen', 'spf', 'glow screen', 'mineral sunscreen'],
    'mask': ['mask', 'facial mist'],
    'exfoliant': ['exfoliant', 'peel', 'polish', 'micro polish'],
    'eyeCream': ['eye cream', 'eye', 'undereye'],
    'other': ['patch', 'dots', 'ointment', 'lip', 'body cream', 'bum bum']
}

# 肤质关键词映射
SKIN_TYPE_KEYWORDS = {
    'dry': ['dry', 'dehydrated', 'moisture', 'hydrat'],
    'oily': ['oily', 'oil control', 'shine control', 'sebum'],
    'sensitive': ['sensitive', 'gentle', 'soothing', 'calm'],
    'combination': ['combination', 'balanced']
}

# 护肤问题关键词映射
CONCERN_KEYWORDS = {
    'acne': ['acne', 'breakout', 'blemish', 'pimple', 'cystic'],
    'aging': ['aging', 'anti-aging', 'wrinkle', 'fine line', 'firm'],
    'pigmentation': ['pigment', 'dark spot', 'discoloration', 'brighten', 'radiance'],
    'sensitivity': ['sensitive', 'irritation', 'redness', 'soothing'],
    'dryness': ['dry', 'dehydrat', 'moisture', 'hydrat'],
    'pores': ['pore', 'clog', 'blackhead']
}

def infer_category(product_name: str, description: str) -> str:
    """推断产品分类"""
    combined = (product_name + ' ' + description).lower()

    for category, keywords in CATEGORY_MAPPING.items():
        for keyword in keywords:
            if keyword in combined:
                return category
    return 'other'

def infer_skin_types(description: str, reviews: List[Dict]) -> List[str]:
    """推断适用肤质"""
    combined = description.lower()
    for review in reviews:
        combined += ' ' + review.get('reviewText', '').lower()

    skin_types = []
    for skin_type, keywords in SKIN_TYPE_KEYWORDS.items():
        for keyword in keywords:
            if keyword in combined:
                skin_types.append(skin_type)
                break

    # 如果没有明确的肤质，默认 normal
    if not skin_types:
        skin_types.append('normal')

    return list(set(skin_types))

def infer_concerns(description: str, reviews: List[Dict]) -> List[str]:
    """推断针对问题"""
    combined = description.lower()
    for review in reviews:
        combined += ' ' + review.get('reviewText', '').lower()

    concerns = []
    for concern, keywords in CONCERN_KEYWORDS.items():
        for keyword in keywords:
            if keyword in combined:
                concerns.append(concern)
                break

    return list(set(concerns))

def extract_ingredients_from_description(description: str) -> List[str]:
    """从描述中提取成分"""
    ingredients = []

    # 常见成分关键词
    common_ingredients = {
        'hyaluronic acid': 'Hyaluronic Acid',
        'niacinamide': 'Niacinamide',
        'vitamin c': 'Vitamin C',
        'vitamin e': 'Vitamin E',
        'retinol': 'Retinol',
        'ceramide': 'Ceramide',
        'peptide': 'Peptides',
        'glycerin': 'Glycerin',
        'salicylic acid': 'Salicylic Acid',
        'azelaic acid': 'Azelaic Acid',
        'lactic acid': 'Lactic Acid',
        'benzoyl peroxide': 'Benzoyl Peroxide',
        'zinc': 'Zinc Oxide',
        'panthenol': 'Panthenol',
        'squalane': 'Squalane',
        'caffeine': 'Caffeine',
        'aha': 'AHA',
        'bha': 'BHA'
    }

    desc_lower = description.lower()
    for keyword, ingredient_name in common_ingredients.items():
        if keyword in desc_lower:
            ingredients.append(ingredient_name)

    return list(set(ingredients))

def calculate_average_rating(reviews: List[Dict]) -> float:
    """计算平均评分"""
    if not reviews:
        return 0.0

    ratings = [r.get('rating', 0) for r in reviews if r.get('rating')]
    if not ratings:
        return 0.0

    return round(sum(ratings) / len(ratings), 1)

def infer_price_range(product_name: str, brand: str) -> str:
    """推断价格档位"""
    luxury_brands = ['La Mer', 'SK-II', 'Estée Lauder', 'Lancôme', 'Shiseido',
                     'SkinCeuticals', 'Vintner', 'Tatcha']
    premium_brands = ['Drunk Elephant', 'Dr. Dennis Gross', 'Paula\'s Choice',
                      'Biologique Recherche', 'Neocutis', 'Eve Lom', 'Mother Science']
    budget_brands = ['CeraVe', 'Neutrogena', 'Aquaphor', 'Differin', 'Hero Cosmetics']

    for luxury in luxury_brands:
        if luxury.lower() in brand.lower() or luxury.lower() in product_name.lower():
            return 'luxury'

    for premium in premium_brands:
        if premium.lower() in brand.lower() or premium.lower() in product_name.lower():
            return 'premium'

    for budget in budget_brands:
        if budget.lower() in brand.lower() or budget.lower() in product_name.lower():
            return 'budget'

    return 'midRange'

def extract_brand(product_name: str) -> str:
    """从产品名中提取品牌"""
    # 常见品牌列表
    brands = [
        'CeraVe', 'The Ordinary', 'Olay', 'SkinCeuticals', 'La Roche-Posay',
        'Drunk Elephant', 'Peach & Lily', 'Differin', 'Rhode', 'Hero Cosmetics',
        'Lancôme', 'Tula Skincare', 'Laneige', 'La Mer', 'Neutrogena',
        'Supergoop', 'Vintner\'s Daughter', 'Eve Lom', 'Shiseido', 'Philosophy',
        'Caudalie', 'Dr. Dennis Gross', 'Shani Darden', 'EADEM', 'MAC',
        'Clinique', 'Dr. Loretta', 'Estée Lauder', 'Eau Thermale Avène',
        'Mother Science', 'KraveBeauty', 'The Outset', 'Blue Lagoon',
        'Dermalogica', 'Aestura', 'Matter of Fact', 'Neocutis', 'Peace Out',
        'Sol de Janeiro', 'Tatcha', 'Glow Recipe', 'Topicals', 'Biologique Recherche'
    ]

    for brand in brands:
        if brand.lower() in product_name.lower():
            return brand

    # 如果没匹配到，取第一个词
    return product_name.split()[0]

def convert_to_skinlab_format(input_file: str, output_file: str):
    """转换为 SkinLab 格式"""

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    products = data['skincareProducts']
    converted_products = []

    print(f"开始转换 {len(products)} 个产品...\n")

    for idx, product in enumerate(products, 1):
        product_name = product['productName']
        description = product['productDescription']
        reviews = product.get('userReviews', [])

        # 提取品牌
        brand = extract_brand(product_name)

        # 生成 ID
        product_id = f"product-{idx:03d}"

        # 推断分类
        category = infer_category(product_name, description)

        # 推断肤质和问题
        skin_types = infer_skin_types(description, reviews)
        concerns = infer_concerns(description, reviews)

        # 提取成分
        ingredients = extract_ingredients_from_description(description)

        # 计算评分
        avg_rating = calculate_average_rating(reviews)

        # 推断价格档位
        price_range = infer_price_range(product_name, brand)

        converted = {
            'id': product_id,
            'name': product_name,
            'brand': brand,
            'category': category,
            'skinTypes': skin_types,
            'concerns': concerns,
            'priceRange': price_range,
            'ingredients': ingredients,
            'averageRating': avg_rating,
            'sampleSize': len(reviews),
            'description': description,
            'sourceUrl': product.get('productName_citation', ''),
            'userReviews': reviews[:3]  # 保留前 3 条评价
        }

        converted_products.append(converted)

        print(f"{idx}. {product_name}")
        print(f"   品牌: {brand}")
        print(f"   分类: {category}")
        print(f"   成分: {len(ingredients)} 个")
        print(f"   评分: {avg_rating}/5 ({len(reviews)} 条评价)")
        print()

    output_data = {'products': converted_products}

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"✓ 转换完成！已保存到: {output_file}")
    print(f"\n统计:")
    print(f"  总产品数: {len(converted_products)}")
    print(f"  平均成分数: {sum(len(p['ingredients']) for p in converted_products) / len(converted_products):.1f}")
    print(f"  平均评分: {sum(p['averageRating'] for p in converted_products if p['averageRating']) / len([p for p in converted_products if p['averageRating']]):.2f}/5")

if __name__ == '__main__':
    convert_to_skinlab_format(
        '/Users/ruirui/Downloads/extract-data-2025-12-25.json',
        '/Users/ruirui/Code/Ai_Code/SkinLab/products_converted.json'
    )
