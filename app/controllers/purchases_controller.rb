class PurchasesController < ApplicationController
  require "payjp"

  def buy
    # 購入する商品を引っ張ってきます。
    @product = Product.find(params[:product_id])
    # @product_photo = Product_Photo.find(params[:product_photo_id])
    # 商品ごとに複数枚写真を登録できるので、一応全部持ってきておきます。
    
    # まずはログインしているか確認
    if user_signed_in?
      @user = current_user
      # クレジットカードが登録されているか確認
      if @user.credit_card.present?
        # 前前前回credentials.yml.encに記載したAPI秘密鍵を呼び出します。
        Payjp.api_key = ENV["PAYJP_ACCESS_KEY"]
        # ログインユーザーのクレジットカード情報を引っ張ってきます。
        @card = CreditCard.find_by(user_id: current_user.id)
        # (以下は以前のcredit_cardsコントローラーのshowアクションとほぼ一緒です)
        # ログインユーザーのクレジットカード情報からPay.jpに登録されているカスタマー情報を引き出す
        customer = Payjp::Customer.retrieve(@card.customer_id)
        # カスタマー情報からカードの情報を引き出す
        @customer_card = customer.cards.retrieve(@card.card_id)

        ##カードのアイコン表示のための定義づけ
        @card_brand = @customer_card.brand
        case @card_brand
        when "Visa"
          # 例えば、Pay.jpからとってきたカード情報の、ブランドが"Visa"だった場合は返り値として
          # (画像として登録されている)Visa.pngを返す
          @card_src = "visa.gif"
        when "JCB"
          @card_src = "jcb.gif"
        when "MasterCard"
          @card_src = "master.png"
        when "American Express"
          @card_src = "amex.gif"
        when "Diners Club"
          @card_src = "diners.gif"
        when "Discover"
          @card_src = "discover.gif"
        end
        # viewの記述を簡略化
        ## 有効期限'月'を定義
        @exp_month = @customer_card.exp_month.to_s
        ## 有効期限'年'を定義
        @exp_year = @customer_card.exp_year.to_s.slice(2,3)
      else
      end
    else
      # ログインしていなければ、商品の購入ができずに、ログイン画面に移動します。
      redirect_to user_session_path, alert: "ログインしてください"
    end
  end

  def pay
    #ちなみに見やすさ考慮し、before_actionなどのリファクタリングなどはあえてしてません。
    @product = Product.find(params[:product_id])
    

    
      @product.with_lock do
        if current_user.credit_card.present?
          # ログインユーザーがクレジットカード登録済みの場合の処理
          # ログインユーザーのクレジットカード情報を引っ張ってきます。
          @card = CreditCard.find_by(user_id: current_user.id)
          # 前前前回credentials.yml.encに記載したAPI秘密鍵を呼び出します。
          Payjp.api_key = ENV["PAYJP_ACCESS_KEY"]
          #登録したカードでの、クレジットカード決済処理
          charge = Payjp::Charge.create(
          # 商品(product)の値段を引っ張ってきて決済金額(amount)に入れる
          amount: @product.price,
          customer: Payjp::Customer.retrieve(@card.customer_id),
          currency: 'jpy'
          )
        else
          Payjp.api_key = ENV["PAYJP_ACCESS_KEY"]
          # ログインユーザーがクレジットカード登録されていない場合(Checkout機能による処理を行います)
          # APIの「Checkout」ライブラリによる決済処理の記述
          Payjp::Charge.create(
          amount: @product.price,
          card: params['payjp-token'], # フォームを送信すると作成・送信されてくるトークン
          currency: 'jpy'
          )
        end
      #購入テーブルに登録処理(今回の実装では言及しませんが一応、、、)
      @product.buyer_user_id = current_user.id
      @product.save
      
      
      end
    end
end

