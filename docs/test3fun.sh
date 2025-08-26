# --------------------------------------
prepareBuilding()
{
  echo "========prepareBuilding....start========="

  local aSubSrcDir="""$1"""
  local aSubBuildDir="$2" 
  echo "aSubSrcDir=$aSubSrcDir"
  echo "aSubBuildDir=$aSubBuildDir" 

  echo "========prepareBuilding....end========="
} 
SrcDir_root=/opt
 
prepareBuilding "${SrcDir_root}/ss" ${SrcDir_root}/bb
# ---------------------------------------
sum_all() {
    # 使用 $((...)) 进行算术运算，正确赋值
    local total=$(( $1 + $2 ))
    echo "in sum_all...1\n"   
    # return $total 
    # **return 命令的局限性**: Shell 函数的 return 语句用于返回退出状态码（0-255 的整数，
    # 0 表示成功，非 0 表示失败）， 不能返回任意数值（如 55 是合法的，但超过 255 会被截断）。
    # 若要返回计算结果，应使用 echo 输出，而非 return。

    echo "in sum_all...2\n" 
    # 通过 echo 输出结果（供外部捕获）
    echo $total
    
    return 2
}

# **函数调用与结果获取**: 即使修正了计算部分，return $total 也无法通过 ret=$(sum_all 22 33)
#  获取结果，因为 $() 捕获的是函数的标准输出（echo 输出的内容），而非 return 的状态码。

# 捕获函数的标准输出（即 echo 输出的结果）
ret=$(sum_all 22 33)
echo "ret====$ret ;;$?"  # 输出：ret====55
# ---------------------------------------
echo "==============check_concat_paths==============="  
check_concat_paths()
{
    # echo "gg.....check_concat_paths():all params=$@"
    local finalPaths=""
    for path in "$@"; do
        if [ -n "${path}" ] && [ -d "${path}" ]; then
            finalPaths="${finalPaths};${path}"
        fi     
    done
    finalPaths="${finalPaths#;}"  # 移除开头的分号
    # echo "gg......check_concat_paths(): finalPaths=${finalPaths}"


    # 验证路径非空
    if [ -z "${finalPaths}" ]; then
        echo "check_concat_paths(): fatal-error: finalPaths is empty,请检查依赖库路径！"
        exit 1
    fi  

    echo "${finalPaths}"
}

INSTALL_PREFIX_root=/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/ubuntu/install
INSTALL_PREFIX_openssl=${INSTALL_PREFIX_root}/openssl
INSTALL_PREFIX_psl=${INSTALL_PREFIX_root}/libpsl
INSTALL_PREFIX_xz=${INSTALL_PREFIX_root}/xz
INSTALL_PREFIX_zstd=${INSTALL_PREFIX_root}/zstd

retPrefixPath=$(check_concat_paths "${INSTALL_PREFIX_openssl}" \
             "${INSTALL_PREFIX_psl}" "${INSTALL_PREFIX_xz}"  "${INSTALL_PREFIX_zstd}")
echo "........retPrefixPath00=${retPrefixPath}"  

check_concat_paths_1()
{
  # echo "gg.....check_concat_paths():all params=$@"
  local finalPaths=""
  for path in "$@"; do
      if [ -n "${path}" ] && [ -d "${path}" ]; then
          # ${cmk_prefixPath:+;} 表示：若 cmk_prefixPath 非空，则添加 ;，避免开头或结尾出现多余分号。
          finalPaths="${finalPaths}${finalPaths:+;}${path}"
      fi     
  done  

  # 验证路径非空
  if [ -z "${finalPaths}" ]; then
      echo "check_concat_paths(): fatal-error: finalPaths is empty,请检查依赖库路径！"
      exit 1
  fi  
  echo "${finalPaths}"
}
INSTALL_PREFIX_geos=${INSTALL_PREFIX_root}/geos
retPrefixPath=$(check_concat_paths_1 "${INSTALL_PREFIX_openssl}" \
             "${INSTALL_PREFIX_psl}" "${INSTALL_PREFIX_xz}"  "${INSTALL_PREFIX_zstd}"\
             "${INSTALL_PREFIX_geos}")
echo "........retPrefixPath01=${retPrefixPath}"                      

# ------------------------------------------
# 初始化空变量
cmk_prefixPath=""
# 遍历所有依赖路径变量
for path in \
  "${INSTALL_PREFIX_zlib}" \
  "${INSTALL_PREFIX_xz}" \
  "${INSTALL_PREFIX_jpegTurbo}" \
  "${INSTALL_PREFIX_openssl}" \
  "${INSTALL_PREFIX_curl}" \
  "${INSTALL_PREFIX_sqlite}"; do
  # 只拼接非空路径，避免空值导致的多余冒号
  if [ -n "$path" ]; then
    # 若已有内容，先加冒号分隔，再拼接新路径
    # ${cmk_prefixPath:+:} 表示：若 cmk_prefixPath 非空，则添加 :，避免开头或结尾出现多余冒号。
    cmk_prefixPath="${cmk_prefixPath}${cmk_prefixPath:+:}${path}"
  fi
done

echo "========== in docs/test01.sh: cmk_prefixPath=${cmk_prefixPath}"    