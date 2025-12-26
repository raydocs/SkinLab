#!/usr/bin/env python3
"""
SkinLab 数据验证和清洗脚本

功能：
1. 验证 ingredients.json 和 products.json 的格式和完整性
2. 清洗数据（去重、标准化、补充缺失字段）
3. 生成数据质量报告

使用方法：
    python3 data_validation.py --input ingredients_seed.json --output ingredients.json --type ingredient
    python3 data_validation.py --input products_seed.json --output products.json --type product
"""

import json
import sys
import argparse
from typing import Dict, List, Any, Tuple
from collections import Counter
import re


# ==================== 配置 ====================

INGREDIENT_FUNCTIONS = [
    "moisturizing", "brightening", "antiAging", "acneFighting",
    "soothing", "exfoliating", "sunProtection", "preservative",
    "fragrance", "other"
]

IRRITATION_LEVELS = ["none", "low", "medium", "high"]

PRODUCT_CATEGORIES = [
    "cleanser", "toner", "serum", "moisturizer", "sunscreen",
    "mask", "exfoliant", "eyeCream", "other"
]

PRICE_RANGES = ["budget", "midRange", "premium", "luxury"]


# ==================== 成分验证 ====================

def validate_ingredient(key: str, ingredient: Dict[str, Any]) -> List[str]:
    """验证单个成分数据"""
    errors = []

    # 必需字段检查
    required_fields = ["name", "function", "safetyRating", "irritationRisk", "benefits"]
    for field in required_fields:
        if field not in ingredient:
            errors.append(f"[{key}] 缺少必需字段: {field}")
        elif not ingredient[field]:
            errors.append(f"[{key}] 字段为空: {field}")

    # function 枚举验证
    if "function" in ingredient:
        func = ingredient["function"]
        if func not in INGREDIENT_FUNCTIONS:
            errors.append(f"[{key}] 无效的 function: '{func}', 期望: {INGREDIENT_FUNCTIONS}")

    # safetyRating 范围验证
    if "safetyRating" in ingredient:
        try:
            rating = int(ingredient["safetyRating"])
            if not (1 <= rating <= 10):
                errors.append(f"[{key}] safetyRating 超出范围 [1-10]: {rating}")
        except (ValueError, TypeError):
            errors.append(f"[{key}] safetyRating 不是有效数值: {ingredient['safetyRating']}")

    # irritationRisk 枚举验证
    if "irritationRisk" in ingredient:
        risk = ingredient["irritationRisk"]
        if risk not in IRRITATION_LEVELS:
            errors.append(f"[{key}] 无效的 irritationRisk: '{risk}', 期望: {IRRITATION_LEVELS}")

    # benefits 数组验证
    if "benefits" in ingredient:
        if not isinstance(ingredient["benefits"], list):
            errors.append(f"[{key}] benefits 必须是数组")
        elif len(ingredient["benefits"]) == 0:
            errors.append(f"[{key}] benefits 不应为空数组")

    # warnings 数组验证（可选）
    if "warnings" in ingredient and ingredient["warnings"] is not None:
        if not isinstance(ingredient["warnings"], list):
            errors.append(f"[{key}] warnings 必须是数组或 null")

    return errors


def clean_ingredient(key: str, ingredient: Dict[str, Any]) -> Dict[str, Any]:
    """清洗单个成分数据"""
    cleaned = ingredient.copy()

    # 标准化 key（小写，去除空格和特殊字符）
    if "name" in cleaned:
        standard_key = re.sub(r'[^a-z0-9]', '', cleaned["name"].lower())
        if standard_key != key:
            print(f"  提示: key '{key}' 不匹配 name '{cleaned['name']}'，建议使用: '{standard_key}'")

    # 转换 safetyRating 为整数
    if "safetyRating" in cleaned:
        try:
            cleaned["safetyRating"] = max(1, min(10, int(cleaned["safetyRating"])))
        except (ValueError, TypeError):
            print(f"  警告: 无法转换 safetyRating，使用默认值 5")
            cleaned["safetyRating"] = 5

    # 标准化 function
    if "function" in cleaned and cleaned["function"] not in INGREDIENT_FUNCTIONS:
        # 尝试映射常见的错误值
        func_mapping = {
            "solvent": "other",
            "humectant": "moisturizing",
            "emollient": "moisturizing",
            "whitening": "brightening",
            "anti-aging": "antiAging",
            "antioxidant": "antiAging"
        }
        original = cleaned["function"]
        cleaned["function"] = func_mapping.get(original.lower(), "other")
        if original.lower() in func_mapping:
            print(f"  映射: function '{original}' → '{cleaned['function']}'")

    # 标准化 irritationRisk
    if "irritationRisk" in cleaned:
        risk = cleaned["irritationRisk"].lower()
        if risk not in IRRITATION_LEVELS:
            # 尝试映射
            risk_mapping = {"minimal": "none", "very low": "low", "moderate": "medium", "severe": "high"}
            cleaned["irritationRisk"] = risk_mapping.get(risk, "low")
            print(f"  映射: irritationRisk '{ingredient['irritationRisk']}' → '{cleaned['irritationRisk']}'")

    # 清洗 aliases（如果存在）
    if "aliases" in cleaned and isinstance(cleaned["aliases"], list):
        cleaned["aliases"] = [re.sub(r'[^a-z0-9]', '', alias.lower()) for alias in cleaned["aliases"]]
        cleaned["aliases"] = list(set(cleaned["aliases"]))  # 去重

    # 清洗 benefits
    if "benefits" in cleaned and isinstance(cleaned["benefits"], list):
        cleaned["benefits"] = [b.strip() for b in cleaned["benefits"] if b.strip()]
        cleaned["benefits"] = list(dict.fromkeys(cleaned["benefits"]))  # 去重但保持顺序

    # 清洗 warnings
    if "warnings" in cleaned and cleaned["warnings"]:
        if isinstance(cleaned["warnings"], list):
            cleaned["warnings"] = [w.strip() for w in cleaned["warnings"] if w.strip()]
            if not cleaned["warnings"]:
                cleaned["warnings"] = None
        else:
            cleaned["warnings"] = None

    return cleaned


def validate_ingredients_json(data: Dict[str, Any]) -> Tuple[List[str], Dict[str, Any]]:
    """验证和清洗整个成分 JSON"""
    errors = []
    cleaned = {}

    print("\n开始验证成分数据...")
    print(f"总计: {len(data)} 个成分\n")

    for key, ingredient in data.items():
        # 验证
        item_errors = validate_ingredient(key, ingredient)
        errors.extend(item_errors)

        # 清洗
        print(f"处理: {key}")
        cleaned[key] = clean_ingredient(key, ingredient)

    # 检查重复的 name
    names = [ing.get("name", "") for ing in data.values()]
    duplicates = [name for name, count in Counter(names).items() if count > 1]
    if duplicates:
        errors.append(f"发现重复的成分名称: {duplicates}")

    return errors, cleaned


# ==================== 产品验证 ====================

def validate_product(product: Dict[str, Any]) -> List[str]:
    """验证单个产品数据"""
    errors = []

    # 必需字段检查
    required_fields = ["id", "name", "brand", "category", "ingredients"]
    for field in required_fields:
        if field not in product:
            errors.append(f"[{product.get('id', 'unknown')}] 缺少必需字段: {field}")

    # category 枚举验证
    if "category" in product:
        cat = product["category"]
        if cat not in PRODUCT_CATEGORIES:
            errors.append(f"[{product.get('id')}] 无效的 category: '{cat}', 期望: {PRODUCT_CATEGORIES}")

    # priceRange 枚举验证
    if "priceRange" in product:
        pr = product["priceRange"]
        if pr not in PRICE_RANGES:
            errors.append(f"[{product.get('id')}] 无效的 priceRange: '{pr}', 期望: {PRICE_RANGES}")

    # ingredients 验证
    if "ingredients" in product:
        ings = product["ingredients"]
        if isinstance(ings, str):
            # 字符串格式（逗号分隔）
            if not ings.strip():
                errors.append(f"[{product.get('id')}] ingredients 为空字符串")
            elif len(ings.split(",")) < 3:
                errors.append(f"[{product.get('id')}] ingredients 少于 3 个（可能不完整）")
        elif isinstance(ings, list):
            # 数组格式
            if len(ings) == 0:
                errors.append(f"[{product.get('id')}] ingredients 为空数组")
            elif len(ings) < 3:
                errors.append(f"[{product.get('id')}] ingredients 少于 3 个（可能不完整）")
        else:
            errors.append(f"[{product.get('id')}] ingredients 格式错误（应为字符串或数组）")

    # averageRating 范围验证
    if "averageRating" in product:
        try:
            rating = float(product["averageRating"])
            if not (0 <= rating <= 5):
                errors.append(f"[{product.get('id')}] averageRating 超出范围 [0-5]: {rating}")
        except (ValueError, TypeError):
            errors.append(f"[{product.get('id')}] averageRating 不是有效数值")

    return errors


def clean_product(product: Dict[str, Any]) -> Dict[str, Any]:
    """清洗单个产品数据"""
    cleaned = product.copy()

    # 标准化 category
    if "category" in cleaned and cleaned["category"] not in PRODUCT_CATEGORIES:
        cat_mapping = {
            "face wash": "cleanser",
            "facial cleanser": "cleanser",
            "essence": "serum",
            "cream": "moisturizer",
            "lotion": "moisturizer",
            "sun protection": "sunscreen",
            "spf": "sunscreen",
            "sheet mask": "mask",
            "eye": "eyeCream"
        }
        original = cleaned["category"].lower()
        for key, value in cat_mapping.items():
            if key in original:
                cleaned["category"] = value
                print(f"  映射: category '{product['category']}' → '{value}'")
                break
        else:
            cleaned["category"] = "other"

    # 清洗 ingredients（转为字符串数组）
    if "ingredients" in cleaned:
        if isinstance(cleaned["ingredients"], str):
            # 拆分字符串
            ings = cleaned["ingredients"]
            # 支持多种分隔符
            ings = re.split(r'[,，、;；]', ings)
            cleaned["ingredients"] = [ing.strip() for ing in ings if ing.strip()]

    # 清洗 price（如果存在）
    if "price" in cleaned:
        try:
            # 去除货币符号和逗号
            price_str = str(cleaned["price"]).replace("$", "").replace(",", "").strip()
            cleaned["price"] = float(price_str)
        except (ValueError, TypeError):
            print(f"  警告: 无法解析 price '{cleaned['price']}'，保持原值")

    # 映射 price → priceRange
    if "price" in cleaned and "priceRange" not in cleaned:
        price = cleaned["price"]
        if price < 50:
            cleaned["priceRange"] = "budget"
        elif price < 150:
            cleaned["priceRange"] = "midRange"
        elif price < 300:
            cleaned["priceRange"] = "premium"
        else:
            cleaned["priceRange"] = "luxury"
        print(f"  推断: priceRange = '{cleaned['priceRange']}' (price: ${price})")

    # 清洗 averageRating
    if "averageRating" in cleaned:
        try:
            rating = float(cleaned["averageRating"])
            cleaned["averageRating"] = max(0, min(5, round(rating, 1)))
        except (ValueError, TypeError):
            print(f"  警告: 无效的 averageRating，使用默认值 0")
            cleaned["averageRating"] = 0

    return cleaned


def validate_products_json(data: Dict[str, Any]) -> Tuple[List[str], Dict[str, Any]]:
    """验证和清洗整个产品 JSON"""
    errors = []

    if "products" not in data:
        errors.append("JSON 缺少 'products' 根键")
        return errors, data

    products = data["products"]

    print("\n开始验证产品数据...")
    print(f"总计: {len(products)} 个产品\n")

    cleaned_products = []

    for product in products:
        # 验证
        item_errors = validate_product(product)
        errors.extend(item_errors)

        # 清洗
        pid = product.get("id", "unknown")
        print(f"处理: {pid} - {product.get('name', '')}")
        cleaned_products.append(clean_product(product))

    # 检查重复的 id
    ids = [p.get("id", "") for p in products]
    duplicates = [pid for pid, count in Counter(ids).items() if count > 1]
    if duplicates:
        errors.append(f"发现重复的产品 ID: {duplicates}")

    return errors, {"products": cleaned_products}


# ==================== 数据质量报告 ====================

def generate_report(data_type: str, data: Dict[str, Any], errors: List[str]):
    """生成数据质量报告"""
    print("\n" + "="*60)
    print(f"数据质量报告 ({data_type})")
    print("="*60)

    if data_type == "ingredient":
        total = len(data)
        print(f"\n总成分数: {total}")

        # 统计 function 分布
        functions = [ing.get("function") for ing in data.values()]
        print("\n功能分类分布:")
        for func, count in Counter(functions).most_common():
            print(f"  {func}: {count}")

        # 统计 irritationRisk 分布
        risks = [ing.get("irritationRisk") for ing in data.values()]
        print("\n刺激性分布:")
        for risk, count in Counter(risks).most_common():
            print(f"  {risk}: {count}")

        # 统计 safetyRating 范围
        ratings = [ing.get("safetyRating", 0) for ing in data.values()]
        print(f"\n安全评级: 平均 {sum(ratings)/len(ratings):.1f}, 范围 [{min(ratings)}, {max(ratings)}]")

        # 字段完整性
        print("\n字段完整性:")
        for field in ["name", "aliases", "function", "safetyRating", "benefits", "warnings"]:
            count = sum(1 for ing in data.values() if field in ing and ing[field])
            print(f"  {field}: {count}/{total} ({100*count/total:.1f}%)")

    elif data_type == "product":
        products = data.get("products", [])
        total = len(products)
        print(f"\n总产品数: {total}")

        # 统计 category 分布
        categories = [p.get("category") for p in products]
        print("\n产品分类分布:")
        for cat, count in Counter(categories).most_common():
            print(f"  {cat}: {count}")

        # 统计 priceRange 分布
        prices = [p.get("priceRange") for p in products]
        print("\n价格档位分布:")
        for pr, count in Counter(prices).most_common():
            print(f"  {pr}: {count}")

        # 统计成分数量
        ing_counts = [len(p.get("ingredients", [])) for p in products if isinstance(p.get("ingredients"), list)]
        if ing_counts:
            print(f"\n成分数量: 平均 {sum(ing_counts)/len(ing_counts):.1f}, 范围 [{min(ing_counts)}, {max(ing_counts)}]")

        # 评分统计
        ratings = [p.get("averageRating", 0) for p in products if p.get("averageRating")]
        if ratings:
            print(f"\n平均评分: {sum(ratings)/len(ratings):.2f}")

    # 错误报告
    print(f"\n发现 {len(errors)} 个问题:")
    if errors:
        for i, error in enumerate(errors[:20], 1):  # 最多显示 20 个
            print(f"  {i}. {error}")
        if len(errors) > 20:
            print(f"  ... 还有 {len(errors)-20} 个问题")
    else:
        print("  ✓ 数据验证通过")

    print("\n" + "="*60 + "\n")


# ==================== 主程序 ====================

def main():
    parser = argparse.ArgumentParser(description="验证和清洗 SkinLab 数据")
    parser.add_argument("--input", required=True, help="输入 JSON 文件路径")
    parser.add_argument("--output", required=True, help="输出 JSON 文件路径")
    parser.add_argument("--type", required=True, choices=["ingredient", "product"], help="数据类型")
    parser.add_argument("--strict", action="store_true", help="严格模式：有错误时不输出文件")

    args = parser.parse_args()

    # 读取输入文件
    print(f"读取文件: {args.input}")
    try:
        with open(args.input, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"错误: 文件不存在 - {args.input}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"错误: JSON 格式错误 - {e}")
        sys.exit(1)

    # 验证和清洗
    if args.type == "ingredient":
        errors, cleaned = validate_ingredients_json(data)
    else:
        errors, cleaned = validate_products_json(data)

    # 生成报告
    generate_report(args.type, cleaned, errors)

    # 输出文件
    if errors and args.strict:
        print("严格模式：由于存在错误，不输出文件")
        sys.exit(1)

    print(f"写入文件: {args.output}")
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    print(f"✓ 完成！输出文件已保存到: {args.output}")

    if errors:
        sys.exit(1)  # 有错误时返回非零退出码
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
