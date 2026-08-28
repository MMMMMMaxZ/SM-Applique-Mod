--MAG's tutorial
MTt = class(nil)

dofile("$MOD_DATA/Scripts/crystalTech/_dofile.lua")

function MTt.init(self)
    print("MTt initiating---")
    self.book = {
        page = 1,
        contentIdx = 1,
        contentLen = 1,
        titlesN = {
            2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42
        },
        scriptsN = {
            3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43
        },
        images = {
            "1.JPG", "2.JPG", "3.JPG", "4.JPG", "5.JPG", "6.JPG", "7.JPG", "8.JPG", "9.JPG", "10.JPG", "11.JPG", "12.JPG", "13.JPG", "14.JPG", "15.JPG", "16.JPG", "17.JPG", "18.JPG", "19.JPG", "20.JPG", "21.JPG"
        },
        titlesImage = {
            "51da94d6-a215-4f69-b569-c45bc1557d0e",
            "51da94d6-a215-4f69-b569-c45bc1557d0c",
            "51da94d6-a215-4f69-b569-c45bc1557d0c",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e5",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e5",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e5",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e6",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e8",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e8",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e9",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e9",
            "1cd32f21-5fe1-4bae-865b-c0c5440253e9",
            "1cd32f21-5fe1-4bae-865b-c0c5440253ea",
            "1cd32f21-5fe1-4bae-865b-c0c5440253eb",
            "1cd32f21-5fe1-4bae-865b-c0c5440253ec",
            "1cd32f21-5fe1-4bae-865b-c0c5440253ed",
            "1cd32f21-5fe1-4bae-865b-c0c5440253ed",
            "51da94d6-a215-4f69-b569-c45bc1557d0f",
            "51da94d6-a215-4f69-b569-c45bc1557d0f",
            "51da94d6-a215-4f69-b569-c45bc1557d0f",
            "51da94d6-a215-4f69-b569-c45bc1557d0f"
        },
        titles = {},
        titlePage = {},
        scripts = {}
    }
    self.book.contentLen = #self.book.titlesN
    for k,v in pairs(self.book.titlesN)do
        self.book.titles[k] = MLines.lines["Mtutorial"][MLines.currentLanguage][v]
        self.book.titlePage[self.book.titles[k]] = k
    end
    for k,v in pairs(self.book.scriptsN)do
        self.book.scripts[k] = MLines.lines["Mtutorial"][MLines.currentLanguage][v]
    end
end