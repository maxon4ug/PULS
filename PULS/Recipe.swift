//
//  Recipe.swift
//  PULS
//
//  Created by Max Surgai on 29.07.17.
//  Copyright © 2017 Max Surgai. All rights reserved.
//

import RealmSwift

class Recipe: Object {
    
    dynamic var title = ""
    dynamic var href = ""
    dynamic var ingredients = ""
    dynamic var thumbnailData = Data()
    
}
