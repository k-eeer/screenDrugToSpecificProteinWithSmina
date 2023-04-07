# 針對特定蛋白尋找可能的治療藥物-描述與用法
某些蛋白結構可能導致疾病，藉由藥物結合則可能使該蛋白因結構改變而不再致病，進而達到治療效果。本腳本將以對接（docking）計算藥物分子與蛋白分子的親和力，選出最容易與該蛋白結合的藥物分子。過程中選用該蛋白比較容易出現的結構，初次對接後再次評估親和力，希望藉此提高準確度希望藉此縮短藥物研發時間。
        
        $bash ./docking.sh

**[額外選項]**  可使用buildSql.sh 建立MySQL表格，儲存藥物分子在PubChem網路資料庫中的頁面網址，以待日後進一步深入參考.(需先安裝套件："$sudo pip install pubchempy")
        
        $bash ./buildSql.sh

若需自動將結果以瀏覽器分頁顯示，請將以下內容前面#字刪除：

        $firefox -new-tab "https://pubchem.ncbi.nlm.nih.gov/compound/$page"

# 運行環境:

  * R-package 'Bio3d'
  * Gromacs
  * Pymol
  * MGLTools
  * Open Babel
  * Smina

# 可能運行結果:

下圖顯示對於該蛋白結合力最高的藥物分子（棒狀彩色結構）以及蛋白分子（綠色緞帶結構）可能的結合情況

![tf1Lig771](output/tf1Lig771.png)

![tf1Lig771Far](output/tf1Lig771Far.png)


# 可能建立的MySQL表格:
最左欄開始分別為結合力最高藥物編號，第一次計算時最容易結合的蛋白結構編號，再次評估之後的最容易結合蛋白結構編號，最右欄則為網路資料庫中對該藥物分子的詳細相關資料頁面url。
![buildSql](output/buildSql.png)



