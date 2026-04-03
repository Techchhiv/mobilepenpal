<?php

return [
    'required' => 'វាល :attribute គឺចាំបាច់។',
    'unique'   => ':attribute នេះត្រូវបានប្រើប្រាស់រួចហើយ។',
    'string'   => ':attribute ត្រូវតែជាខ្សែអក្សរ។',
    'email'    => ':attribute ត្រូវតែជាអាសយដ្ឋានអ៊ីមែលត្រឹមត្រូវ។',
    'min'      => [
        'numeric' => ':attribute ត្រូវតែយ៉ាងហោចណាស់ :min ។',
        'file'    => ':attribute ត្រូវតែយ៉ាងហោចណាស់ :min គីឡូបៃ។',
        'string'  => ':attribute ត្រូវមានយ៉ាងហោចណាស់ :min តួអក្សរ។',
        'array'   => ':attribute ត្រូវមានយ៉ាងហោចណាស់ :min ធាតុ។',
    ],
    'max'      => [
        'numeric' => ':attribute មិនត្រូវធំជាង :max ឡើយ។',
        'file'    => ':attribute មិនត្រូវធំជាង :max គីឡូបៃឡើយ។',
        'string'  => ':attribute មិនត្រូវលើសពី :max តួអក្សរឡើយ។',
        'array'   => ':attribute មិនត្រូវមានលើសពី :max ធាតុឡើយ។',
    ],
    'exists'   => ':attribute ដែលបានជ្រើសរើសមិនត្រឹមត្រូវទេ។',
    'integer'  => ':attribute ត្រូវតែជាចំនួនគត់។',
    'date'     => ':attribute មិនមែនជាកាលបរិច្ឆេទត្រឹមត្រូវទេ។',

    'attributes' => [
        'phone'             => 'លេខទូរស័ព្ទ',
        'email'             => 'អ៊ីមែល',
        'password'          => 'លេខសម្ងាត់',
        'first_name'        => 'នាមត្រកូល',
        'last_name'         => 'នាមខ្លួន',
        'parent_first_name' => 'នាមត្រកូលអាណាព្យាបាល',
        'parent_last_name'  => 'នាមខ្លួនអាណាព្យាបាល',
        'name'              => 'ឈ្មោះ',
    ],
];
