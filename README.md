[![Build Status](https://travis-ci.org/semdinsp/randprize.png)](https://travis-ci.org/semdinsp/randprize)
[![Code Climate](https://codeclimate.com/repos/524654d9c7f3a31b29038e3a/badges/58ed8386e3e6d266c7ac/gpa.png)](https://codeclimate.com/repos/524654d9c7f3a31b29038e3a/feed)
[![Gem Version](https://badge.fury.io/rb/randprize.png)](http://badge.fury.io/rb/randprize)

randprize gem
============

Given a hash of prizes and odds randomly return a prize.

Prize Hash with odds
=====================

    @headstails={ "T"=> {'odds'=> 2,'name'=>'win tails','value'=>0},"H"=> {'odds'=> 2,'name'=>'win heads','value'=>1}}
    @dice={}
    1.upto(6) {|i| @dice[i.to_s]= {'odds'=> 6,'name'=>"rolled #{i}",'value'=>i} }
    @large={ "GP"=> {'odds'=> 100,'name'=>'grandprize','value'=>50000},"H"=> {'odds'=> 'REMAINING','name'=>'win heads','value'=>1}}

The REMAINING flag fills in rest of prize deck with the value and should have value 0 for prize statistics

Usage
=======

    @headstails={ "T"=> {'odds'=> 2,'name'=>'win tails','value'=>0},"H"=> {'odds'=> 2,'name'=>'win heads','value'=>1}}
    @pm=Randprize::ManagePrizes.new
    @pm.prize_list(@headstails)
    aprize=@pm.random_prize
